# G1 Layer2: start Tiramisu64 and poll boot oracles in host logs
param(
    [string]$PlayerExe = "C:\Program Files\BlueStacks_nxt\HD-Player.exe",
    [string]$LogDir = "C:\ProgramData\BlueStacks_nxt\Logs",
    [int]$TimeoutSec = 600,
    [int]$StabilizationSec = 95,
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
Get-CimInstance Win32_Process | Where-Object {
    $_.Name -eq "HD-Player.exe" -and $_.CommandLine -match '--instance\s+Tiramisu64(?:\s|$)'
} | ForEach-Object {
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 2
$before = Get-Date
Start-Process -FilePath $PlayerExe -ArgumentList "--instance","Tiramisu64" -WindowStyle Hidden
$patterns = @(
    @{ id="system_mounted"; rx="A16DBG: system mounted" },
    @{ id="init_second"; rx="stage2 about to exec /init" },
    @{ id="odsign"; rx="On-device signing done\." },
    @{ id="boot_completed"; rx="processing action \(sys\.boot_completed=1\)|wait_for_boot_completed done" },
    @{ id="activity"; rx="hcallOnActivityDisplayed" },
    # Host ready mark: newer builds log tag [Ready]; older paths used "Player state: ready"
    @{ id="ready"; rx="Player state: ready|\[Ready\]" },
    @{ id="hide_boot"; rx="fUiHideBootProgressBar" }
)
$fatalPatterns = @(
    @{ id = "kernel_panic"; rx = "Kernel panic - not syncing" },
    @{ id = "vm_start_failed"; rx = "GlueStartVM failed" },
    @{ id = "zygote_preload_failed"; rx = "Error preloading android\.app\.SystemServiceRegistry" },
    @{ id = "zygote_boot_class_missing"; rx = "NoClassDefFoundError: Class not found using the boot class loader" },
    @{ id = "zygote_fatal"; rx = "System zygote died with fatal exception" },
    @{ id = "package_state_null"; rx = "PackageStateInternal\.getAppId\(\).*null object reference" },
    @{ id = "apps_filter_crash"; rx = "AppsFilterBase\.shouldFilterApplication" },
    @{ id = "systemui_crash_loop"; rx = "Process com\.android\.systemui has crashed too many times" },
    @{ id = "system_server_watchdog"; rx = "WATCHDOG KILLING SYSTEM PROCESS|watchdog.*system_server" },
    @{ id = "system_server_terminated"; rx = "system server.*has terminated|system_server.*(?:died|terminated)" },
    @{ id = "zygote_system_server_exit"; rx = "Exit zygote because system server.*terminated" },
    @{ id = "rescue_party_reboot"; rx = "reboot: Restarting system with command 'RescueParty'" }
)
$found = @{}
$fatalFound = @{}
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
    foreach ($pat in $fatalPatterns) {
        if (-not $fatalFound.ContainsKey($pat.id) -and
            ($logs | Select-String -Pattern $pat.rx -Quiet)) {
            $fatalFound[$pat.id] = $true
        }
    }
    $elapsed = [int]((Get-Date) - $before).TotalSeconds
    Write-Host "[$elapsed s] oracles: $($found.Keys.Count)/$($patterns.Count)"
    if ($found.Keys.Count -ge $patterns.Count -or $fatalFound.Keys.Count -gt 0) { break }
}

if ($found.Keys.Count -ge $patterns.Count -and $fatalFound.Keys.Count -eq 0 -and
    $StabilizationSec -gt 0) {
    Write-Host "A16DBG:G1: boot oracles complete; stabilizing for ${StabilizationSec}s"
    Start-Sleep -Seconds $StabilizationSec
}

$stabilityLogs = @()
foreach ($name in @("Player.log", "Player.log.1", "BstkCore.log")) {
    $stabilityLogs += Get-LogLinesSince -Path (Join-Path $LogDir $name) -Since $before
}
$stabilityFailures = @($fatalFound.Keys)
foreach ($pat in $fatalPatterns) {
    if ($stabilityFailures -notcontains $pat.id -and
        ($stabilityLogs | Select-String -Pattern $pat.rx -Quiet)) {
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
