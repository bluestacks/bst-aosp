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
    [void](Invoke-AdbBounded -Arguments @(
        "shell", "sh", "-c",
        "test -x /system/bin/mountsf && mountpoint -q /mnt/windows/BstSharedFolder"
    ))
} catch {
    Write-Warning $_
    $failures += "shared_folder"
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
foreach ($factory in @(
    "android.hardware.drm@1.3::IDrmFactory/widevine",
    "android.hardware.drm@1.3::ICryptoFactory/widevine"
)) {
    if ($hidl -notmatch [regex]::Escape($factory)) { $failures += "widevine:$factory" }
}

foreach ($service in @(
    "media.audio_flinger", "SurfaceFlinger", "media.camera",
    "connectivity", "phone", "isub"
)) {
    $result = Invoke-AdbBounded -Arguments @("shell", "service", "check", $service)
    if ($result -notmatch 'found') { $failures += "service:$service" }
}

if ($failures.Count -gt 0) {
    throw "Runtime regression failed: $($failures -join ', ')"
}
Write-Host "A16DBG:G1: runtime regression PASS"
exit 0
