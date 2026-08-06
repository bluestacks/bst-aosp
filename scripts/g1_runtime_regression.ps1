# Android-16 post-boot regression checks for the promoted BlueStacks guest.
param(
    [string]$AdbExe = "C:\Program Files\BlueStacks_nxt\HD-Adb.exe",
    [string]$Serial,
    [int]$AdbTimeoutSec = 20,
    [switch]$CheckOnly
)

$ErrorActionPreference = "Stop"
if (-not (Test-Path $AdbExe)) { throw "HD-Adb missing: $AdbExe" }
if ($CheckOnly) {
    Write-Host "A16DBG:ANDROID16: runtime-regression CHECK OK; guest was not queried"
    exit 0
}

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

[void](Invoke-AdbBounded -Arguments @("logcat", "-c"))
[void](Invoke-AdbBounded -Arguments @(
    "shell", "am", "start", "-a", "android.intent.action.MAIN",
    "-c", "android.intent.category.HOME"
))
Start-Sleep -Seconds 15
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

foreach ($service in @("media.audio_flinger", "SurfaceFlinger")) {
    $result = Invoke-AdbBounded -Arguments @("shell", "service", "check", $service)
    if ($result -notmatch 'found') { $failures += "service:$service" }
}

if ($failures.Count -gt 0) {
    throw "Runtime regression failed: $($failures -join ', ')"
}
Write-Host "A16DBG:G1: runtime regression PASS"
exit 0
