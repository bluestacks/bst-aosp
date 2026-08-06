# G1 Layer2: start Tiramisu64 and poll boot oracles in host logs
param(
    [string]$PlayerExe = "C:\Program Files\BlueStacks_nxt\HD-Player.exe",
    [string]$LogDir = "C:\ProgramData\BlueStacks_nxt\Logs",
    [int]$TimeoutSec = 600,
    [int]$StabilizationSec = 75,
    [string]$ArtifactIdentity = "C:\ProgramData\BlueStacks_nxt\Engine\Tiramisu64\Root.vhd.identity",
    [switch]$CheckOnly
)
$ErrorActionPreference = "Stop"
if (-not (Test-Path $PlayerExe)) { throw "HD-Player missing: $PlayerExe" }
if (-not (Test-Path $LogDir)) { throw "LogDir missing: $LogDir" }
if (-not (Test-Path $ArtifactIdentity)) { throw "Artifact identity missing: $ArtifactIdentity" }
if ($CheckOnly) {
    Write-Host "A16DBG:ANDROID16: boot-verify CHECK OK; player was not started"
    exit 0
}

function Get-LogLinesSince {
    param([string]$Path, [datetime]$Since)
    if (-not (Test-Path $Path)) { return @() }
    $cutoff = $Since.ToString("yyyy-MM-dd HH:mm:ss")
    $lines = Get-Content $Path -ErrorAction SilentlyContinue
    $out = @()
    foreach ($line in $lines) {
        if ($line.Length -ge 19 -and $line.Substring(0, 19) -ge $cutoff) { $out += $line }
    }
    return $out
}

Write-Host "A16DBG:G1: boot-verify start timeout=${TimeoutSec}s"
Write-Host "A16DBG:G1: deployed artifact identity:"
Get-Content $ArtifactIdentity
Get-Process -Name "HD-Player","BstkSVC","BstkVMMgr" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
$before = Get-Date
Start-Process -FilePath $PlayerExe -ArgumentList "--instance","Tiramisu64" -WindowStyle Hidden
$patterns = @(
    @{ id="system_mounted"; rx="A16DBG: system mounted" },
    @{ id="init_second"; rx="init second stage started" },
    @{ id="odsign"; rx="odsign.key.done" },
    @{ id="boot_completed"; rx="processing action \(sys\.boot_completed=1\)" },
    @{ id="activity"; rx="hcallOnActivityDisplayed" },
    # Host ready mark: newer builds log tag [Ready]; older paths used "Player state: ready"
    @{ id="ready"; rx="Player state: ready|\[Ready\]" },
    @{ id="hide_boot"; rx="fUiHideBootProgressBar" }
)
$found = @{}
$deadline = (Get-Date).AddSeconds($TimeoutSec)
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 15
    $logs = @()
    # Player.log rotates to .1 on cold start; scan both or slow boots miss oracles.
    foreach ($name in @("Player.log","Player.log.1","BstkCore.log")) {
        $logs += Get-LogLinesSince -Path (Join-Path $LogDir $name) -Since $before
    }
    foreach ($pat in $patterns) {
        if (-not $found.ContainsKey($pat.id)) {
            if ($logs | Select-String -Pattern $pat.rx -Quiet) { $found[$pat.id] = $true }
        }
    }
    $elapsed = [int]((Get-Date) - $before).TotalSeconds
    Write-Host "[$elapsed s] oracles: $($found.Keys.Count)/$($patterns.Count)"
    if ($found.Keys.Count -ge $patterns.Count) { break }
}

if ($found.Keys.Count -ge $patterns.Count -and $StabilizationSec -gt 0) {
    Write-Host "A16DBG:G1: boot oracles complete; stabilizing for ${StabilizationSec}s"
    Start-Sleep -Seconds $StabilizationSec
}

$stabilityLogs = @()
foreach ($name in @("Player.log", "Player.log.1", "BstkCore.log")) {
    $stabilityLogs += Get-LogLinesSince -Path (Join-Path $LogDir $name) -Since $before
}
$fatalPatterns = @(
    @{ id = "package_state_null"; rx = "PackageStateInternal\.getAppId\(\).*null object reference" },
    @{ id = "apps_filter_crash"; rx = "AppsFilterBase\.shouldFilterApplication" },
    @{ id = "systemui_crash_loop"; rx = "Process com\.android\.systemui has crashed too many times" }
)
$stabilityFailures = @()
foreach ($pat in $fatalPatterns) {
    if ($stabilityLogs | Select-String -Pattern $pat.rx -Quiet) {
        $stabilityFailures += $pat.id
    }
}

Write-Host "=== G1 boot oracle results ==="
$failed = @()
foreach ($pat in $patterns) {
    $ok = $found.ContainsKey($pat.id)
    if (-not $ok) { $failed += $pat.id }
    Write-Host ("  [{0}] {1}" -f ($(if($ok){"PASS"}else{"FAIL"})), $pat.id)
}
foreach ($id in $stabilityFailures) {
    Write-Host "  [FAIL] stability:$id"
}
Write-Host "A16DBG:G1: boot-verify done elapsed=$([int]((Get-Date)-$before).TotalSeconds)s"
if ($failed.Count -gt 0 -or $stabilityFailures.Count -gt 0) {
    $allFailures = @($failed) + @($stabilityFailures | ForEach-Object { "stability:$_" })
    Write-Error "Boot oracle failed: $($allFailures -join ', ')"
    exit 1
}
exit 0
