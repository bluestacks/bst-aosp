# G1 Layer2: start Tiramisu64 and poll boot oracles in host logs
param(
    [string]$PlayerExe = "C:\Program Files\BlueStacks_nxt\HD-Player.exe",
    [string]$LogDir = "C:\ProgramData\BlueStacks_nxt\Logs",
    [int]$TimeoutSec = 600,
    [int]$StabilizationSec = 95,
    [string]$ArtifactIdentity = "C:\ProgramData\BlueStacks_nxt\Engine\Tiramisu64\Root.vhd.identity",
    [string]$AdbExe = "C:\Program Files\BlueStacks_nxt\HD-Adb.exe",
    [string]$AdbSerial = "127.0.0.1:5556",
    [string]$ExpectedHostGlVendor = "Intel",
    [int]$GraphicsProbeRetries = 5,
    [double]$MinNonBlackRatio = 0.005,
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

function Get-GuestFramebufferProbe {
    param(
        [Parameter(Mandatory = $true)][string]$Executable,
        [Parameter(Mandatory = $true)][string]$Serial,
        [Parameter(Mandatory = $true)][double]$RequiredNonBlackRatio
    )

    $guestPath = "/data/local/tmp/g1-graphics-probe.png"
    $localPath = Join-Path $env:TEMP "g1-graphics-probe-$PID.png"
    Remove-Item -LiteralPath $localPath -Force -ErrorAction SilentlyContinue
    try {
        & $Executable connect $Serial | Out-Null
        & $Executable -s $Serial shell screencap -p $guestPath | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "guest screencap failed with exit $LASTEXITCODE" }
        & $Executable -s $Serial pull $guestPath $localPath | Out-Null
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $localPath)) {
            throw "guest screencap pull failed with exit $LASTEXITCODE"
        }

        Add-Type -AssemblyName System.Drawing
        $bitmap = [System.Drawing.Bitmap]::FromFile($localPath)
        try {
            $step = 8
            $sampleCount = 0
            $nonBlackCount = 0
            for ($y = 0; $y -lt $bitmap.Height; $y += $step) {
                for ($x = 0; $x -lt $bitmap.Width; $x += $step) {
                    $pixel = $bitmap.GetPixel($x, $y)
                    $sampleCount++
                    if (($pixel.R + $pixel.G + $pixel.B) -gt 45) { $nonBlackCount++ }
                }
            }
            $ratio = if ($sampleCount -gt 0) { $nonBlackCount / $sampleCount } else { 0.0 }
            $hash = (Get-FileHash -LiteralPath $localPath -Algorithm SHA256).Hash.ToLowerInvariant()
            return [pscustomobject]@{
                Ok = $ratio -ge $RequiredNonBlackRatio
                Width = $bitmap.Width
                Height = $bitmap.Height
                Bytes = (Get-Item -LiteralPath $localPath).Length
                NonBlackRatio = $ratio
                Sha256 = $hash
            }
        } finally {
            $bitmap.Dispose()
        }
    } finally {
        Remove-Item -LiteralPath $localPath -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "A16DBG:G1: boot-verify start timeout=${TimeoutSec}s"
Write-Host "A16DBG:G1: deployed artifact identity:"
Get-Content $ArtifactIdentity
Get-CimInstance Win32_Process | Where-Object {
    $_.Name -eq "HD-Player.exe" -and $_.CommandLine -match '--instance(?:"|\s)+Tiramisu64(?:"|\s|$)'
} | ForEach-Object {
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 2
$before = Get-Date
Start-Process -FilePath $PlayerExe -ArgumentList "--instance","Tiramisu64" -WindowStyle Hidden
$patterns = @(
    @{ id="system_mounted"; rx="EXT4-fs \(loop[0-9]+\): mounted filesystem .* ro with ordered data mode" },
    @{ id="stage2"; rx="Running stage2 script|stage2 about to exec /init" },
    @{ id="runtime_apex_mounted"; rx="A16DBG: mounted apex com\.android\.runtime on /dev/loop[0-9]+" },
    @{ id="boot_completed"; rx="processing action \(sys\.boot_completed=1\)|wait_for_boot_completed done|Boot complete:" },
    @{ id="activity"; rx="hcallOnActivityDisplayed" },
    # Host ready mark: newer builds log tag [Ready]; older paths used "Player state: ready"
    @{ id="ready"; rx="Player state: ready|\[Ready\]" },
    @{ id="hide_boot"; rx="fUiHideBootProgressBar" }
)
if ($ExpectedHostGlVendor) {
    $patterns += @{
        id = "host_gl_vendor"
        rx = "GL_VENDOR\s*=\s*$([regex]::Escape($ExpectedHostGlVendor))"
    }
}
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
    @{ id = "rescue_party_reboot"; rx = "reboot: Restarting system with command 'RescueParty'" },
    @{ id = "kernel_rcu_stall"; rx = "rcu_preempt detected expedited stalls on CPUs/tasks" }
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

$graphicsProbe = $null
$graphicsFailure = $null
if ($found.Keys.Count -ge $patterns.Count -and $stabilityFailures.Count -eq 0) {
    if (-not (Test-Path -LiteralPath $AdbExe)) {
        $graphicsFailure = "guest_framebuffer_adb_missing"
    } else {
        for ($attempt = 1; $attempt -le $GraphicsProbeRetries; $attempt++) {
            try {
                $graphicsProbe = Get-GuestFramebufferProbe -Executable $AdbExe -Serial $AdbSerial `
                    -RequiredNonBlackRatio $MinNonBlackRatio
                $probeSummary = ("A16DBG:G1: guest-framebuffer attempt={0} size={1}x{2} " +
                    "bytes={3} non_black_ratio={4:N6} sha256={5}") -f $attempt,
                    $graphicsProbe.Width, $graphicsProbe.Height, $graphicsProbe.Bytes,
                    $graphicsProbe.NonBlackRatio, $graphicsProbe.Sha256
                Write-Host $probeSummary
                if ($graphicsProbe.Ok) { break }
            } catch {
                Write-Host "A16DBG:G1: guest-framebuffer attempt=$attempt error=$($_.Exception.Message)"
            }
            if ($attempt -lt $GraphicsProbeRetries) { Start-Sleep -Seconds 5 }
        }
        if ($null -eq $graphicsProbe -or -not $graphicsProbe.Ok) {
            $graphicsFailure = "guest_framebuffer_black_or_unreadable"
        }
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
if ($graphicsFailure) {
    Write-Host "  [FAIL] graphics:$graphicsFailure"
} elseif ($graphicsProbe -and $graphicsProbe.Ok) {
    Write-Host "  [PASS] guest_framebuffer"
}
Write-Host "A16DBG:G1: boot-verify done elapsed=$([int]((Get-Date)-$before).TotalSeconds)s"
if ($failed.Count -gt 0 -or $stabilityFailures.Count -gt 0 -or $graphicsFailure) {
    $allFailures = @($failed) + @($stabilityFailures | ForEach-Object { "stability:$_" })
    if ($graphicsFailure) { $allFailures += "graphics:$graphicsFailure" }
    Write-Error "Boot oracle failed: $($allFailures -join ', ')"
    exit 1
}
exit 0
