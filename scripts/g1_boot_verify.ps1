# G1 Layer2: start Tiramisu64 and poll boot oracles in host logs
param(
    [string]$PlayerExe = "C:\Program Files\BlueStacks_nxt\HD-Player.exe",
    [string]$LogDir = "C:\ProgramData\BlueStacks_nxt\Logs",
    [int]$TimeoutSec = 600
)
$ErrorActionPreference = "Continue"
if (-not (Test-Path $PlayerExe)) { throw "HD-Player missing: $PlayerExe" }

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
Get-Process -Name "HD-Player","BstkSVC","BstkVMMgr" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
$before = Get-Date
Start-Process -FilePath $PlayerExe -ArgumentList "--instance","Tiramisu64" -WindowStyle Normal
$patterns = @(
    @{ id="system_mounted"; rx="A16DBG: system mounted" },
    @{ id="init_second"; rx="init second stage started" },
    @{ id="odsign"; rx="odsign.key.done" },
    @{ id="boot_completed"; rx="processing action \(sys\.boot_completed=1\)" },
    @{ id="activity"; rx="hcallOnActivityDisplayed" },
    # 2026-07-17 修正：HD-Player 的 ready 标记是行内状态 tag `[Ready]`（如 `Tiramisu64 [Ready]`），
    # 不是 `Player state: ready` 短语（永不命中，导致成功 boot 也被判 FAIL）。
    @{ id="ready"; rx="\[Ready\]" },
    @{ id="hide_boot"; rx="fUiHideBootProgressBar" }
)
$found = @{}
$deadline = (Get-Date).AddSeconds($TimeoutSec)
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 15
    $logs = @()
    foreach ($name in @("Player.log","BstkCore.log")) {
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
Write-Host "=== G1 boot oracle results ==="
foreach ($pat in $patterns) {
    $ok = $found.ContainsKey($pat.id)
    Write-Host ("  [{0}] {1}" -f ($(if($ok){"PASS"}else{"FAIL"})), $pat.id)
}
Write-Host "A16DBG:G1: boot-verify done elapsed=$([int]((Get-Date)-$before).TotalSeconds)s"
