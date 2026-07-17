# G1 Layer2 clean re-verify: stop -> clear Player.log -> relaunch -> poll oracles + capture REAL launcher markers
$ErrorActionPreference = "Continue"
$LogDir    = "C:\ProgramData\BlueStacks_nxt\Logs"
$PlayerExe = "C:\Program Files\BlueStacks_nxt\HD-Player.exe"
$EngineDir = "C:\ProgramData\BlueStacks_nxt\Engine\Tiramisu64"
$pl = Join-Path $LogDir "Player.log"

# 1. stop running instance
Write-Host "A16DBG:REVERIFY: stopping HD-Player/BstkSVC/BstkVMMgr"
Get-Process -Name "HD-Player","BstkSVC","BstkVMMgr" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 5

# 2. clear log (move aside, keep history)
if (Test-Path $pl) {
    $ts = Get-Date -Format "yyyyMMdd-HHmmss"
    $mv = Join-Path $LogDir "Player.log.prerestart.$ts"
    Move-Item $pl $mv -Force -ErrorAction SilentlyContinue
    Write-Host "A16DBG:REVERIFY: moved old Player.log -> $(Split-Path $mv -Leaf)"
}

# 3. md5 of currently-deployed Root.vhd (now readable, not locked) -> tells us WHICH vhd this re-verify tests
$vhd = Join-Path $EngineDir "Root.vhd"
try { $h = (Get-FileHash $vhd -Algorithm MD5).Hash; Write-Host "A16DBG:REVERIFY: deployed Root.vhd md5=$h  size=$((Get-Item $vhd).Length)" }
catch { Write-Host "A16DBG:REVERIFY: Root.vhd md5 unreadable: $_" }

# 4. launch fresh
$before = Get-Date
Write-Host "A16DBG:REVERIFY: launching HD-Player --instance Tiramisu64 at $before"
Start-Process -FilePath $PlayerExe -ArgumentList "--instance","Tiramisu64" -WindowStyle Normal

# 5. poll the verify-script's 7 oracles (to test if harness can detect this boot)
$oracles = @(
    @{ id="system_mounted"; rx="A16DBG: system mounted" },
    @{ id="init_second";    rx="init second stage started" },
    @{ id="odsign";         rx="odsign.key.done" },
    @{ id="boot_completed"; rx="processing action \(sys\.boot_completed=1\)" },
    @{ id="activity";       rx="hcallOnActivityDisplayed" },
    @{ id="ready";          rx="Player state: ready" },
    @{ id="hide_boot";      rx="fUiHideBootProgressBar" }
)
$found = @{}
$deadline = (Get-Date).AddSeconds(180)
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 10
    $logs = Get-Content $pl -ErrorAction SilentlyContinue
    if ($logs) {
        foreach ($pat in $oracles) {
            if (-not $found.ContainsKey($pat.id) -and ($logs | Select-String -Pattern $pat.rx -Quiet)) { $found[$pat.id] = $true }
        }
    }
    $el = [int]((Get-Date) - $before).TotalSeconds
    Write-Host ("A16DBG:REVERIFY: [{0}s] oracles {1}/{2}" -f $el, $found.Keys.Count, $oracles.Count)
    if ($found.Keys.Count -ge $oracles.Count) { break }
}

Write-Host "=== clean reverify: verify-script oracle results ==="
foreach ($pat in $oracles) {
    $ok = $found.ContainsKey($pat.id)
    Write-Host ("  [{0}] {1}" -f ($(if($ok){"PASS"}else{"FAIL"})), $pat.id)
}

# 6. capture REAL launcher/boot-success markers in THIS BS version (filter out ZYGLOG flood)
Write-Host "=== real launcher markers (non-ZYGLOG), first 50 ==="
$logs = Get-Content $pl -ErrorAction SilentlyContinue
if ($logs) {
    $markerRx = "boot_completed|bootanim|launcher|uncube|ActivityDisplayed|fUiHide|system_server|starting service 'zygote'|Displayed #|sys.boot_completed|wm_:|ActivityTaskManager"
    $logs | Where-Object { $_ -notmatch "A16DBG: ZYGLOG" } | Select-String -Pattern $markerRx | Select-Object -First 50 | ForEach-Object { Write-Host $_.Line }
    Write-Host "=== total lines: $($logs.Count) ; ZYGLOG flood lines: $(($logs | Select-String -Pattern 'A16DBG: ZYGLOG' -Quiet).Count) ==="
    Write-Host "=== last 15 non-ZYGLOG lines ==="
    $logs | Where-Object { $_ -notmatch "A16DBG: ZYGLOG" } | Select-Object -Last 15 | ForEach-Object { Write-Host $_ }
}
Write-Host "A16DBG:REVERIFY: done elapsed=$([int]((Get-Date)-$before).TotalSeconds)s"
