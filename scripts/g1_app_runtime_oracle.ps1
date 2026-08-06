# App-UID Android-16 behavior oracle for the promoted BlueStacks guest.
param(
    [Parameter(Mandatory = $true)]
    [string]$ApkPath,
    [string]$AdbExe = "C:\Program Files\BlueStacks_nxt\HD-Adb.exe",
    [string]$Serial,
    [int]$AdbTimeoutSec = 20,
    [int]$OracleTimeoutSec = 70,
    [switch]$CheckOnly
)

$ErrorActionPreference = "Stop"
$packageName = "com.bluestacks.a16oracle"
$componentName = "$packageName/.OracleActivity"
if (-not (Test-Path $AdbExe)) { throw "HD-Adb missing: $AdbExe" }
if ($CheckOnly) {
    Write-Host "A16DBG:ANDROID16: app-runtime-oracle CHECK OK; APK and guest not queried"
    exit 0
}
if (-not (Test-Path $ApkPath -PathType Leaf)) { throw "Oracle APK missing: $ApkPath" }
if ($OracleTimeoutSec -lt 30) { throw "OracleTimeoutSec must be at least 30" }

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
    if (-not $WithoutSerial) { $processArguments += "-s", $Serial }
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
        throw "Expected exactly one online HD-Adb device, found $($devices.Count)"
    }
    $Serial = $devices[0]
}

$identityPath = "$ApkPath.identity"
if (-not (Test-Path $identityPath -PathType Leaf)) {
    throw "Oracle APK identity sidecar missing: $identityPath"
}
$identity = @{}
Get-Content $identityPath | ForEach-Object {
    if ($_ -match '^([^=]+)=(.*)$') { $identity[$Matches[1]] = $Matches[2] }
}
$actualHash = (Get-FileHash -Algorithm SHA256 $ApkPath).Hash.ToLowerInvariant()
if ($identity.apk_sha256 -ne $actualHash) {
    throw "Oracle APK identity mismatch: expected $($identity.apk_sha256), got $actualHash"
}
if ($identity.stage -ne "android16-promotion" -or
    $identity.branch -ne "aosp16-bst-merge" -or
    $identity.tree -notmatch '(?:^|/)android-16$' -or
    $identity.tree -match 'aosp16' -or
    $identity.head -notmatch '^[0-9a-f]{40}$' -or
    $identity.oracle_source_sha256 -notmatch '^[0-9a-f]{64}$') {
    throw "Oracle APK was not built from the Android-16 promotion tree"
}

$installed = $false
try {
    $installOutput = Invoke-AdbBounded -Arguments @("install", "-r", $ApkPath) -TimeoutSec 60
    if ($installOutput -notmatch '(?m)^Success\s*$') {
        throw "Oracle APK install did not report Success: $installOutput"
    }
    $installed = $true
    foreach ($permission in @(
        "android.permission.CAMERA",
        "android.permission.ACCESS_FINE_LOCATION",
        "android.permission.NEARBY_WIFI_DEVICES"
    )) {
        [void](Invoke-AdbBounded -Arguments @(
            "shell", "pm", "grant", $packageName, $permission
        ))
    }

    $packageRecord = Invoke-AdbBounded -Arguments @(
        "shell", "cmd", "package", "list", "packages", "-U", $packageName
    )
    if ($packageRecord -notmatch 'uid:(\d+)') {
        throw "Unable to read oracle app UID: $packageRecord"
    }
    $oracleUid = $Matches[1]

    [void](Invoke-AdbBounded -Arguments @("logcat", "-c"))
    [void](Invoke-AdbBounded -Arguments @("shell", "am", "force-stop", $packageName))
    $startOutput = Invoke-AdbBounded -Arguments @(
        "shell", "am", "start", "-W", "-n", $componentName
    ) -TimeoutSec 30
    if ($startOutput -notmatch '(?m)^Status:\s+ok\s*$') {
        throw "Oracle activity failed to start: $startOutput"
    }

    $deadline = [DateTime]::UtcNow.AddSeconds($OracleTimeoutSec)
    $logs = ""
    do {
        Start-Sleep -Seconds 2
        $logs = Invoke-AdbBounded -Arguments @("logcat", "-d", "-v", "brief") `
            -TimeoutSec 30
        if ($logs -match 'A16ORACLE:DONE:') { break }
    } while ([DateTime]::UtcNow -lt $deadline)

    if ($logs -notmatch 'A16ORACLE:DONE:uid=(\d+)') {
        throw "App runtime oracle timed out before DONE"
    }
    if ($Matches[1] -ne $oracleUid) {
        throw "Oracle UID changed: package=$oracleUid log=$($Matches[1])"
    }
    $failLines = @($logs -split "`n" | Where-Object { $_ -match 'A16ORACLE:FAIL:' })
    if ($failLines.Count -gt 0) {
        throw "App runtime oracle failures:`n$($failLines -join "`n")"
    }
    foreach ($name in @(
        "wifi_identity", "network_presentation", "skia_render",
        "audio_track", "camera_frame", "download_retry_sent"
    )) {
        if ($logs -notmatch "A16ORACLE:PASS:$([regex]::Escape($name)):") {
            throw "App runtime oracle did not report PASS for $name"
        }
    }
    if ($logs -notmatch "Ignoring retry request from uid\s+$oracleUid(?:\D|$)") {
        throw "DownloadProvider denial for oracle UID $oracleUid was not observed"
    }

    Write-Host "A16DBG:G1: app runtime oracle PASS uid=$oracleUid"
} finally {
    if ($installed) {
        try {
            [void](Invoke-AdbBounded -Arguments @("uninstall", $packageName) -TimeoutSec 45)
        } catch {
            Write-Warning "Unable to uninstall runtime oracle: $($_.Exception.Message)"
        }
    }
}
