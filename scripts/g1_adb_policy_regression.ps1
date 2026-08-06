# Fail-closed ADB allowlist oracle for the promoted Android-16 guest.
param(
    [string]$AdbExe = "C:\Program Files\BlueStacks_nxt\HD-Adb.exe",
    [string]$Serial,
    [int]$AdbTimeoutSec = 30,
    [switch]$CheckOnly
)

$ErrorActionPreference = "Stop"
$policyPath = "/data/downloads/.adbcmd"
if (-not (Test-Path $AdbExe)) { throw "HD-Adb missing: $AdbExe" }
if ($CheckOnly) {
    Write-Host "A16DBG:ANDROID16: adb-policy-regression CHECK OK; guest was not queried"
    exit 0
}

function Invoke-AdbCapture {
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
    return [pscustomobject]@{
        ExitCode = $process.ExitCode
        Output = $output -join "`n"
    }
}

function Invoke-AdbBounded {
    param(
        [string[]]$Arguments,
        [switch]$WithoutSerial,
        [int]$TimeoutSec = $AdbTimeoutSec
    )
    $result = Invoke-AdbCapture -Arguments $Arguments -WithoutSerial:$WithoutSerial `
        -TimeoutSec $TimeoutSec
    if ($result.ExitCode -ne 0) {
        throw "HD-Adb failed ($($result.ExitCode)): $($Arguments -join ' ')`n$($result.Output)"
    }
    return $result.Output
}

function Resolve-AdbSerial {
    if (-not [string]::IsNullOrWhiteSpace($Serial)) { return $Serial }
    $deviceOutput = Invoke-AdbBounded -Arguments @("devices") -WithoutSerial
    $devices = @($deviceOutput -split "`n" | ForEach-Object {
        if ($_ -match '^(\S+)\s+device(?:\s|$)') { $Matches[1] }
    })
    if ($devices.Count -ne 1) {
        throw "Expected exactly one online HD-Adb device, found $($devices.Count)"
    }
    return $devices[0]
}

$Serial = Resolve-AdbSerial
$accessOverride = (Invoke-AdbBounded -Arguments @(
    "shell", "getprop", "bst.enable_adb_access"
)).Trim()
if ($accessOverride -notin @("", "0")) {
    throw "ADB restriction is intentionally bypassed by bst.enable_adb_access=$accessOverride"
}
$adbdUid = (Invoke-AdbBounded -Arguments @("shell", "id", "-u")).Trim()
if ($adbdUid -ne "2000") { throw "adbd shell is not unprivileged: uid=$adbdUid" }

$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("a16-adb-policy-" + [guid]::NewGuid())
[void](New-Item -ItemType Directory -Path $tempDir)
$originalPath = Join-Path $tempDir "original.adbcmd"
$restrictivePath = Join-Path $tempDir "restrictive.adbcmd"
$readbackPath = Join-Path $tempDir "readback.adbcmd"
$policyChanged = $false

Write-Host "A16DBG:G1: adb policy regression serial=$Serial"
try {
    [void](Invoke-AdbBounded -Arguments @("pull", $policyPath, $originalPath) -TimeoutSec 45)
    if (-not (Test-Path $originalPath -PathType Leaf) -or
        (Get-Item $originalPath).Length -eq 0) {
        throw "ADB policy file is missing or empty after pull: $policyPath"
    }
    $originalHash = (Get-FileHash -Algorithm SHA256 $originalPath).Hash.ToLowerInvariant()

    # Keep exactly the transport and file-sync prefixes needed for guaranteed restoration.
    [System.IO.File]::WriteAllText($restrictivePath, "sync,$policyPath",
        [System.Text.Encoding]::ASCII)
    [void](Invoke-AdbBounded -Arguments @("push", $restrictivePath, $policyPath) -TimeoutSec 45)
    $policyChanged = $true

    $probe = "a16_nonallowlisted_probe_" + [guid]::NewGuid().ToString("N")
    $denied = Invoke-AdbCapture -Arguments @("shell", $probe)
    if ($denied.ExitCode -eq 0) {
        throw "Non-allowlisted ADB shell request unexpectedly succeeded"
    }
    if ($denied.Output -match '(?i)(not found|inaccessible|permission denied)') {
        throw "Probe reached the guest shell instead of being rejected by ADB: $($denied.Output)"
    }
    if ($denied.Output -notmatch '(?i)(closed|connection|protocol|failed|error)' -and
        -not [string]::IsNullOrWhiteSpace($denied.Output)) {
        throw "Unexpected ADB denial response: $($denied.Output)"
    }
    if ((Invoke-AdbBounded -Arguments @("get-state")).Trim() -ne "device") {
        throw "ADB transport did not remain online after the denied request"
    }

    [void](Invoke-AdbBounded -Arguments @("push", $originalPath, $policyPath) -TimeoutSec 45)
    [void](Invoke-AdbBounded -Arguments @("pull", $policyPath, $readbackPath) -TimeoutSec 45)
    $readbackHash = (Get-FileHash -Algorithm SHA256 $readbackPath).Hash.ToLowerInvariant()
    if ($readbackHash -ne $originalHash) {
        throw "ADB policy restore hash mismatch: expected=$originalHash actual=$readbackHash"
    }
    $policyChanged = $false
    Write-Host "A16DBG:G1: adb policy regression PASS policy_sha256=$originalHash"
} finally {
    if ($policyChanged -and (Test-Path $originalPath -PathType Leaf)) {
        try {
            [void](Invoke-AdbBounded -Arguments @("push", $originalPath, $policyPath) -TimeoutSec 45)
        } catch {
            Write-Warning "Unable to restore $policyPath`: $($_.Exception.Message)"
        }
    }
    Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}
