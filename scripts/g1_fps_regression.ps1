# Frame-pacing and bounded CPU oracle for the promoted Android-16 guest.
param(
    [string]$AdbExe = "C:\Program Files\BlueStacks_nxt\HD-Adb.exe",
    [string]$Serial,
    [int]$TestFps = 30,
    [int]$SettleSec = 4,
    [int]$MeasureSec = 15,
    [double]$PeriodTolerancePercent = 8.0,
    [switch]$CheckOnly
)

$ErrorActionPreference = "Stop"
if (-not (Test-Path $AdbExe)) { throw "HD-Adb missing: $AdbExe" }
if ($CheckOnly) {
    Write-Host "A16DBG:ANDROID16: fps-regression CHECK OK; guest was not queried"
    exit 0
}
if ($TestFps -lt 10 -or $TestFps -gt 240) { throw "TestFps must be between 10 and 240" }
if ($SettleSec -lt 2) { throw "SettleSec must be at least 2" }
if ($MeasureSec -lt 10) { throw "MeasureSec must be at least 10" }

function Invoke-AdbBounded {
    param(
        [string[]]$Arguments,
        [switch]$WithoutSerial,
        [int]$TimeoutSec = 30
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

function Get-GuestScalar {
    param([string[]]$Arguments)
    return (Invoke-AdbBounded -Arguments $Arguments).Trim()
}

function Get-SchedulerPeriodNs {
    $output = Invoke-AdbBounded -Arguments @("shell", "dumpsys", "SurfaceFlinger") `
        -TimeoutSec 45
    foreach ($line in $output -split "`n") {
        if ($line -match '^\s*app duration:\s+(\d{6,12}) ns(?:\s|$)') {
            $period = [int64]$Matches[1]
            if ($period -gt 1000000 -and $period -lt 1000000000) { return $period }
        }
    }
    throw "SurfaceFlinger did not expose the Scheduler app duration: $output"
}

function Assert-VsyncPeriod {
    param([int]$Fps, [int64]$ActualPeriod)
    $expected = [int64][math]::Floor(1000000000.0 / $Fps)
    $difference = [math]::Abs([double]$ActualPeriod - $expected)
    $percent = 100.0 * $difference / $expected
    if ($percent -gt $PeriodTolerancePercent) {
        throw ("FPS period mismatch: fps={0} expected={1}ns actual={2}ns delta={3:N2}%" -f `
            $Fps, $expected, $ActualPeriod, $percent)
    }
    Write-Host ("  fps={0} period={1}ns expected={2}ns delta={3:N2}%" -f `
        $Fps, $ActualPeriod, $expected, $percent)
}

function Set-GuestFps {
    param([int]$Fps)
    [void](Invoke-AdbBounded -Arguments @("shell", "setprop", "bst.max_fps", "$Fps"))
    Start-Sleep -Seconds $SettleSec
    $readback = Get-GuestScalar -Arguments @("shell", "getprop", "bst.max_fps")
    if ($readback -ne "$Fps") { throw "bst.max_fps readback mismatch: set=$Fps got=$readback" }
}

function Get-ProcessPid {
    param([string]$Name)
    $pidValue = Get-GuestScalar -Arguments @("shell", "pidof", $Name)
    if ($pidValue -notmatch '^\d+$') { throw "Expected one $Name process, got: $pidValue" }
    return [int]$pidValue
}

function Get-ComposerPid {
    $processes = Invoke-AdbBounded -Arguments @("shell", "ps", "-A", "-o", "PID,NAME")
    $matches = @($processes -split "`n" | ForEach-Object {
        if ($_ -match '^\s*(\d+)\s+(\S*graphics\.composer\S*)\s*$') {
            [pscustomobject]@{ Pid = [int]$Matches[1]; Name = $Matches[2] }
        }
    })
    if ($matches.Count -ne 1) {
        throw "Expected one graphics composer process, found $($matches.Count)"
    }
    return $matches[0]
}

function Get-CpuJiffies {
    param([int]$ProcessId)
    $value = Get-GuestScalar -Arguments @(
        "shell", "awk", "'{print `$14 + `$15}'", "/proc/$ProcessId/stat"
    )
    if ($value -notmatch '^\d+$') { throw "Invalid CPU jiffies for pid $ProcessId`: $value" }
    return [int64]$value
}

function Measure-ProcessCpu {
    param(
        [int]$Fps,
        [int]$SurfaceFlingerPid,
        [int]$ComposerPid,
        [int]$ClockTicks
    )
    $sfBefore = Get-CpuJiffies -ProcessId $SurfaceFlingerPid
    $composerBefore = Get-CpuJiffies -ProcessId $ComposerPid
    Start-Sleep -Seconds $MeasureSec
    $sfAfter = Get-CpuJiffies -ProcessId $SurfaceFlingerPid
    $composerAfter = Get-CpuJiffies -ProcessId $ComposerPid
    $sfDelta = $sfAfter - $sfBefore
    $composerDelta = $composerAfter - $composerBefore
    $runawayLimit = [int64]$ClockTicks * $MeasureSec * 4
    if ($sfDelta -lt 0 -or $composerDelta -lt 0 -or
        $sfDelta -gt $runawayLimit -or $composerDelta -gt $runawayLimit) {
        throw "FPS CPU bound failed: fps=$Fps sf=$sfDelta composer=$composerDelta limit=$runawayLimit"
    }
    Write-Host "  fps=$Fps cpu_jiffies surfaceflinger=$sfDelta composer=$composerDelta limit=$runawayLimit"
}

$Serial = Resolve-AdbSerial
$originalText = Get-GuestScalar -Arguments @("shell", "getprop", "bst.max_fps")
if ($originalText -notmatch '^\d+$') { throw "bst.max_fps is not numeric: $originalText" }
$originalFps = [int]$originalText
if ($originalFps -lt 10 -or $originalFps -gt 240) {
    throw "bst.max_fps must be a positive restorable value between 10 and 240, got $originalFps"
}
if ($TestFps -eq $originalFps) { $TestFps = if ($originalFps -eq 30) { 45 } else { 30 } }

$bootId = Get-GuestScalar -Arguments @("shell", "cat", "/proc/sys/kernel/random/boot_id")
$systemServerPid = Get-ProcessPid -Name "system_server"
$surfaceFlingerPid = Get-ProcessPid -Name "surfaceflinger"
$composer = Get-ComposerPid
$clockTicksText = Get-GuestScalar -Arguments @("shell", "getconf", "CLK_TCK")
if ($clockTicksText -notmatch '^\d+$') { throw "Invalid CLK_TCK: $clockTicksText" }
$clockTicks = [int]$clockTicksText
$changed = $false

Write-Host "A16DBG:G1: fps regression serial=$Serial original=$originalFps test=$TestFps"
try {
    Set-GuestFps -Fps $originalFps
    Assert-VsyncPeriod -Fps $originalFps -ActualPeriod (Get-SchedulerPeriodNs)

    Set-GuestFps -Fps $TestFps
    $changed = $true
    Assert-VsyncPeriod -Fps $TestFps -ActualPeriod (Get-SchedulerPeriodNs)
    Measure-ProcessCpu -Fps $TestFps -SurfaceFlingerPid $surfaceFlingerPid `
        -ComposerPid $composer.Pid -ClockTicks $clockTicks

    Set-GuestFps -Fps $originalFps
    $changed = $false
    Assert-VsyncPeriod -Fps $originalFps -ActualPeriod (Get-SchedulerPeriodNs)
    Measure-ProcessCpu -Fps $originalFps -SurfaceFlingerPid $surfaceFlingerPid `
        -ComposerPid $composer.Pid -ClockTicks $clockTicks

    if ((Get-GuestScalar -Arguments @("shell", "cat", "/proc/sys/kernel/random/boot_id")) -ne $bootId) {
        throw "Guest rebooted during FPS regression"
    }
    if ((Get-ProcessPid -Name "system_server") -ne $systemServerPid) {
        throw "system_server restarted during FPS regression"
    }
    if ((Get-ProcessPid -Name "surfaceflinger") -ne $surfaceFlingerPid) {
        throw "SurfaceFlinger restarted during FPS regression"
    }
    if ((Get-ComposerPid).Pid -ne $composer.Pid) {
        throw "Graphics composer restarted during FPS regression"
    }
    Write-Host "A16DBG:G1: fps regression PASS"
} finally {
    if ($changed) {
        try {
            Set-GuestFps -Fps $originalFps
        } catch {
            Write-Warning "Unable to restore bst.max_fps=$originalFps`: $($_.Exception.Message)"
        }
    }
}
