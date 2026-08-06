# Android-16 post-boot regression checks for the promoted BlueStacks guest.
param(
    [string]$AdbExe = "C:\Program Files\BlueStacks_nxt\HD-Adb.exe",
    [string]$Serial,
    [int]$AdbTimeoutSec = 20,
    [int]$StabilityWindowSec = 95,
    [int]$StabilityPollSec = 5,
    [switch]$CheckOnly
)

$ErrorActionPreference = "Stop"
if (-not (Test-Path $AdbExe)) { throw "HD-Adb missing: $AdbExe" }
if ($CheckOnly) {
    Write-Host "A16DBG:ANDROID16: runtime-regression CHECK OK; guest was not queried"
    exit 0
}
if ($StabilityWindowSec -lt 15) { throw "StabilityWindowSec must be at least 15" }
if ($StabilityPollSec -lt 1) { throw "StabilityPollSec must be positive" }

function Invoke-AdbBounded {
    param(
        [string[]]$Arguments,
        [switch]$WithoutSerial,
        [int]$TimeoutSec = $AdbTimeoutSec
    )

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $AdbExe
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.CreateNoWindow = $true
    $processArguments = @()
    if (-not $WithoutSerial) {
        $processArguments += "-s", $Serial
    }
    $processArguments += $Arguments
    $startInfo.Arguments = ($processArguments | ForEach-Object {
        if ($_ -notmatch '[\s"]') { $_ }
        else { '"' + $_.Replace('"', '\"') + '"' }
    }) -join ' '

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    [void]$process.Start()
    $stdout = $process.StandardOutput.ReadToEndAsync()
    $stderr = $process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit($TimeoutSec * 1000)) {
        try { $process.Kill($true) } catch { $process.Kill() }
        throw "HD-Adb timed out after ${TimeoutSec}s: $($Arguments -join ' ')"
    }
    $output = @($stdout.Result.TrimEnd(), $stderr.Result.TrimEnd()) |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    if ($process.ExitCode -ne 0) {
        throw "HD-Adb failed ($($process.ExitCode)): $($Arguments -join ' ')`n$($output -join "`n")"
    }
    return $output -join "`n"
}

if ([string]::IsNullOrWhiteSpace($Serial)) {
    $deviceOutput = Invoke-AdbBounded -Arguments @("devices") -WithoutSerial
    $devices = @($deviceOutput -split "`n" | ForEach-Object {
        if ($_ -match '^(\S+)\s+device(?:\s|$)') { $Matches[1] }
    })
    if ($devices.Count -ne 1) {
        throw "Expected exactly one online HD-Adb device, found $($devices.Count): $($devices -join ', ')"
    }
    $Serial = $devices[0]
}

$failures = @()
Write-Host "A16DBG:G1: runtime regression start serial=$Serial"

if ((Invoke-AdbBounded -Arguments @("get-state")).Trim() -ne "device") {
    $failures += "adb_state"
}
if ((Invoke-AdbBounded -Arguments @("shell", "getprop", "sys.boot_completed")).Trim() -ne "1") {
    $failures += "boot_completed"
}

$home = Invoke-AdbBounded -Arguments @(
    "shell", "cmd", "package", "resolve-activity", "--brief",
    "-a", "android.intent.action.MAIN", "-c", "android.intent.category.HOME"
)
if ($home -notmatch '^com\.uncube\.launcher3/') { $failures += "home_resolver" }

$bootIdBefore = (Invoke-AdbBounded -Arguments @(
    "shell", "cat", "/proc/sys/kernel/random/boot_id"
)).Trim()
$systemServerPidBefore = (Invoke-AdbBounded -Arguments @(
    "shell", "pidof", "system_server"
)).Trim()
if ($bootIdBefore -notmatch '^[0-9a-f-]{36}$') { $failures += "boot_id_before" }
if ($systemServerPidBefore -notmatch '^\d+$') { $failures += "system_server_pid_before" }

$bootLogs = Invoke-AdbBounded -Arguments @("logcat", "-b", "all", "-d", "-v", "brief") `
    -TimeoutSec 30
$retainedHidlPattern =
    'android\.hardware\.(audio|audio\.effect|camera\.provider|configstore|drm|' +
    'graphics\.allocator|graphics\.composer|light|media\.omx|power|soundtrigger)'
if ($bootLogs -match "Service $retainedHidlPattern.*must be in VINTF manifest" -or
    $bootLogs -match "Could not register service $retainedHidlPattern") {
    $failures += "retained_hidl_registration"
}

[void](Invoke-AdbBounded -Arguments @("logcat", "-c"))
[void](Invoke-AdbBounded -Arguments @(
    "shell", "am", "start", "-a", "android.intent.action.MAIN",
    "-c", "android.intent.category.HOME"
))
$stabilityTimer = [System.Diagnostics.Stopwatch]::StartNew()
while ($stabilityTimer.Elapsed.TotalSeconds -lt $StabilityWindowSec) {
    $remaining = $StabilityWindowSec - [int]$stabilityTimer.Elapsed.TotalSeconds
    Start-Sleep -Seconds ([Math]::Min($StabilityPollSec, [Math]::Max(1, $remaining)))
    try {
        $state = (Invoke-AdbBounded -Arguments @("get-state")).Trim()
        $bootIdNow = (Invoke-AdbBounded -Arguments @(
            "shell", "cat", "/proc/sys/kernel/random/boot_id"
        )).Trim()
        $systemServerPidNow = (Invoke-AdbBounded -Arguments @(
            "shell", "pidof", "system_server"
        )).Trim()
    } catch {
        throw "Runtime stability failed after $([int]$stabilityTimer.Elapsed.TotalSeconds)s: $($_.Exception.Message)"
    }
    if ($state -ne "device") {
        throw "Runtime stability failed: HD-Adb state changed to '$state'"
    }
    if ($bootIdNow -ne $bootIdBefore) {
        throw "Runtime stability failed: guest boot ID changed from $bootIdBefore to $bootIdNow"
    }
    if ($systemServerPidNow -ne $systemServerPidBefore) {
        throw "Runtime stability failed: system_server PID changed from $systemServerPidBefore to $systemServerPidNow"
    }
}
$stabilityTimer.Stop()

$activities = Invoke-AdbBounded -Arguments @("shell", "dumpsys", "activity", "activities")
if ($activities -notmatch 'mResumedActivity:.*com\.uncube\.launcher3') {
    $failures += "launcher_not_resumed"
}
$logs = Invoke-AdbBounded -Arguments @("logcat", "-d", "-v", "brief") -TimeoutSec 30
if ($logs -match 'PackageStateInternal\.getAppId\(\).*null object reference' -or
    $logs -match 'AppsFilterBase\.shouldFilterApplication' -or
    $logs -match 'Process com\.android\.systemui has crashed too many times') {
    $failures += "package_state_crash"
}
if ($logs -match '(?i)WATCHDOG KILLING SYSTEM PROCESS' -or
    $logs -match '(?i)Exit zygote because system server.*terminated' -or
    $logs -match '(?i)system_server.*(?:died|has terminated)') {
    $failures += "system_server_watchdog"
}

try {
    $sharedProbeCommand =
        'probe=/mnt/windows/BstSharedFolder/.a16_runtime_probe; ' +
        'trap "rm -f $probe" EXIT; ' +
        'test -x /system/bin/mountsf && mountpoint -q /mnt/windows/BstSharedFolder && ' +
        'printf A16_RUNTIME_PROBE > $probe && ' +
        'test "$(cat $probe)" = A16_RUNTIME_PROBE'
    [void](Invoke-AdbBounded -Arguments @(
        "shell", "sh", "-c", $sharedProbeCommand
    ))
} catch {
    Write-Warning $_
    $failures += "shared_folder"
}

try {
    $xmlProbeCommand =
        'probe=/data/local/tmp/a16_runtime_probe.xml; ' +
        'trap "rm -f $probe" EXIT; ' +
        'test -x /system/bin/xmllint && ' +
        'printf "<a16><runtime/></a16>\n" > $probe && ' +
        '/system/bin/xmllint --noout $probe && test -s $probe'
    [void](Invoke-AdbBounded -Arguments @("shell", "sh", "-c", $xmlProbeCommand))
} catch {
    Write-Warning $_
    $failures += "device_xmllint"
}

try {
    $lockDisabled = (Invoke-AdbBounded -Arguments @(
        "shell", "locksettings", "get-disabled"
    )).Trim()
    if ($lockDisabled -notmatch '^(true|false)$') {
        $failures += "locksettings_state:$lockDisabled"
    }
} catch {
    Write-Warning $_
    $failures += "locksettings_query"
}

$houdiniCommand =
    'test x$(getprop ro.dalvik.vm.native.bridge) = xlibnb.so && ' +
    'test x$(getprop ro.dalvik.vm.isa.arm64) = xx86_64 && ' +
    'test -x /system/bin/houdini64 && test -f /system/lib64/libhoudini.so && ' +
    'test -f /system/lib64/libtcb.so && test -e /proc/sys/fs/binfmt_misc/arm64_dyn && ' +
    'test -e /proc/sys/fs/binfmt_misc/arm64_exe'
try {
    [void](Invoke-AdbBounded -Arguments @("shell", "sh", "-c", $houdiniCommand))
} catch {
    Write-Warning $_
    $failures += "houdini_sanity"
}

$entropy = (Invoke-AdbBounded -Arguments @(
    "shell", "cat", "/proc/sys/kernel/random/entropy_avail"
)).Trim()
$entropyValue = 0
if (-not [int]::TryParse($entropy, [ref]$entropyValue) -or $entropyValue -le 0) {
    $failures += "kernel_entropy"
}

$defaultRoute = Invoke-AdbBounded -Arguments @("shell", "ip", "-4", "route", "show", "default")
if ($defaultRoute -notmatch '(?m)^default\s') { $failures += "default_ipv4_route" }

try {
    [void](Invoke-AdbBounded -Arguments @("shell", "cmd", "wifi", "status"))
    [void](Invoke-AdbBounded -Arguments @("shell", "dumpsys", "wifi") -TimeoutSec 30)
    $wifiMac = (Invoke-AdbBounded -Arguments @(
        "shell", "getprop", "bst.wifi_mac_addr"
    )).Trim().ToLowerInvariant()
    $persistedWifiMac = (Invoke-AdbBounded -Arguments @(
        "shell", "cat", "/data/downloads/.tmp/.ma"
    )).Trim().ToLowerInvariant()
    if ($wifiMac -notmatch '^(?:[0-9a-f]{2}:){5}[0-9a-f]{2}$') {
        $failures += "wifi_mac_property:$wifiMac"
    } elseif ($persistedWifiMac -ne $wifiMac) {
        $failures += "wifi_mac_persistence:$persistedWifiMac"
    }
} catch {
    Write-Warning $_
    $failures += "wifi_mac_readback"
}

$operatorNumeric = (Invoke-AdbBounded -Arguments @(
    "shell", "getprop", "gsm.operator.numeric"
)).Trim()
if ($operatorNumeric -notmatch '^\d{5,6}$') { $failures += "telephony_operator" }

$imeState = (Invoke-AdbBounded -Arguments @(
    "shell", "getprop", "init.svc.imeservice"
)).Trim()
try {
    [void](Invoke-AdbBounded -Arguments @("shell", "test", "-x", "/system/bin/bstime"))
} catch {
    Write-Warning $_
    $failures += "bstime_payload"
}
if ($imeState -ne "running") { $failures += "imeservice_state:$imeState" }

$hidl = Invoke-AdbBounded -Arguments @("shell", "lshal", "-i") -TimeoutSec 30
foreach ($interface in @(
    "android.hardware.audio@7.0::IDevicesFactory/default",
    "android.hardware.audio.effect@7.0::IEffectsFactory/default",
    "android.hardware.camera.provider@2.4::ICameraProvider/legacy/0",
    "android.hardware.configstore@1.1::ISurfaceFlingerConfigs/default",
    "android.hardware.drm@1.0::IDrmFactory/default",
    "android.hardware.drm@1.0::ICryptoFactory/default",
    "android.hardware.drm@1.3::IDrmFactory/widevine",
    "android.hardware.drm@1.3::ICryptoFactory/widevine",
    "android.hardware.graphics.allocator@2.0::IAllocator/default",
    "android.hardware.graphics.composer@2.1::IComposer/default",
    "android.hardware.light@2.0::ILight/default",
    "android.hardware.media.omx@1.0::IOmx/default",
    "android.hardware.media.omx@1.0::IOmxStore/default",
    "android.hardware.power@1.0::IPower/default",
    "android.hardware.soundtrigger@2.3::ISoundTriggerHw/default"
)) {
    if ($hidl -notmatch [regex]::Escape($interface)) { $failures += "hidl:$interface" }
}

foreach ($service in @(
    "media.audio_flinger", "SurfaceFlinger", "media.camera",
    "connectivity", "phone", "isub", "lock_settings",
    "android.hardware.bluetooth.IBluetoothHci/default",
    "android.hardware.dumpstate.IDumpstateDevice/default",
    "android.hardware.gnss.IGnss/default",
    "android.hardware.memtrack.IMemtrack/default",
    "android.hardware.power.IPower/default",
    "android.hardware.usb.IUsb/default",
    "android.hardware.security.keymint.IKeyMintDevice/default",
    "android.hardware.security.keymint.IRemotelyProvisionedComponent/default",
    "android.hardware.security.secureclock.ISecureClock/default",
    "android.hardware.security.sharedsecret.ISharedSecret/default"
)) {
    $result = Invoke-AdbBounded -Arguments @("shell", "service", "check", $service)
    if ($result -notmatch 'found') { $failures += "service:$service" }
}

[void](Invoke-AdbBounded -Arguments @("logcat", "-c"))
$settingsChecks = @(
    [pscustomobject]@{
        Name = "android.settings.SETTINGS"
        Arguments = @("shell", "am", "start", "-W", "-a", "android.settings.SETTINGS")
    },
    [pscustomobject]@{
        Name = "com.bluestacks.settings/.SettingsActivity"
        Arguments = @(
            "shell", "am", "start", "-W", "-n",
            "com.bluestacks.settings/.SettingsActivity"
        )
    }
)
foreach ($settingsCheck in $settingsChecks) {
    try {
        $startResult = Invoke-AdbBounded `
            -Arguments $settingsCheck.Arguments -TimeoutSec 30
        if ($startResult -notmatch '(?m)^Status:\s+ok\s*$') {
            $failures += "settings_start:$($settingsCheck.Name)"
        }
    } catch {
        Write-Warning $_
        $failures += "settings_start:$($settingsCheck.Name)"
    }
}
[void](Invoke-AdbBounded -Arguments @(
    "shell", "am", "start", "-W", "-a", "android.intent.action.MAIN",
    "-c", "android.intent.category.HOME"
))
$settingsLogs = Invoke-AdbBounded -Arguments @(
    "logcat", "-d", "-v", "brief"
) -TimeoutSec 30
if ($settingsLogs -match
    '(?is)FATAL EXCEPTION.*?Process:\s+(?:com\.android\.settings|com\.bluestacks\.settings)') {
    $failures += "settings_crash"
}
$activitiesAfterSettings = Invoke-AdbBounded -Arguments @(
    "shell", "dumpsys", "activity", "activities"
)
if ($activitiesAfterSettings -notmatch 'mResumedActivity:.*com\.uncube\.launcher3') {
    $failures += "launcher_not_resumed_after_settings"
}

if ($failures.Count -gt 0) {
    throw "Runtime regression failed: $($failures -join ', ')"
}
Write-Host "A16DBG:G1: runtime regression PASS"
exit 0
