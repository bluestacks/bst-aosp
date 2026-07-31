# G1 Layer2: deploy bst_x86_64/qvirt Root.vhd to win Tiramisu64 instance
param(
    [string]$CloudHost = "markxu@172.16.6.191",
    [string]$RemotePkg = "~/releases/Baklava64/bst-v5.22.210_Baklava64-local",
    [string]$EngineDir = "C:\ProgramData\BlueStacks_nxt\Engine\Tiramisu64",
    [switch]$CheckOnly
)
$ErrorActionPreference = "Stop"
if (-not (Test-Path $EngineDir)) { throw "EngineDir missing: $EngineDir" }
if ($CheckOnly) {
    if (-not (Get-Command scp -ErrorAction SilentlyContinue)) { throw "scp is unavailable" }
    Write-Host "A16DBG:ANDROID16: deploy CHECK OK; no process stopped and no file copied"
    exit 0
}
Set-Location $EngineDir
Write-Host "A16DBG:G1: win-deploy start" -ForegroundColor Cyan
Get-Process -Name "HD-Player","BstkSVC","BstkVMMgr" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Remove-Item Root.vhd.new -Force -ErrorAction SilentlyContinue
Remove-Item Root.vhd.identity.new -Force -ErrorAction SilentlyContinue
& scp "${CloudHost}:${RemotePkg}/Root.vhd" "Root.vhd.new"
if ($LASTEXITCODE -ne 0) { throw "scp Root.vhd failed with exit $LASTEXITCODE" }
& scp "${CloudHost}:${RemotePkg}/Root.vhd.identity" "Root.vhd.identity.new"
if ($LASTEXITCODE -ne 0) { throw "scp Root.vhd.identity failed with exit $LASTEXITCODE" }
if (-not (Test-Path "Root.vhd.new")) { throw "scp Root.vhd failed" }
if (-not (Test-Path "Root.vhd.identity.new")) { throw "scp identity failed" }
$sz = (Get-Item "Root.vhd.new").Length
# cont.21+: packed Root can be ~998MiB (still valid VHD); keep floor below historical ~1.0GiB
if ($sz -lt 800MB) { throw "Root.vhd.new too small: $sz" }
$identity = @{}
Get-Content "Root.vhd.identity.new" | ForEach-Object {
    if ($_ -match '^([^=]+)=(.*)$') { $identity[$Matches[1]] = $Matches[2] }
}
if (-not $identity["artifact_sha256"]) { throw "identity has no artifact_sha256" }
$localSha256 = (Get-FileHash "Root.vhd.new" -Algorithm SHA256).Hash.ToLowerInvariant()
if ($localSha256 -ne $identity["artifact_sha256"].ToLowerInvariant()) {
    throw "Root.vhd SHA256 mismatch: local=$localSha256 remote=$($identity['artifact_sha256'])"
}
$ts = Get-Date -Format "yyyyMMdd-HHmm"
Copy-Item Root.vhd "Root.vhd.bak.$ts" -Force -ErrorAction SilentlyContinue
Move-Item Root.vhd.new Root.vhd -Force
Move-Item Root.vhd.identity.new Root.vhd.identity -Force
Get-FileHash Root.vhd -Algorithm MD5 | Format-List
Get-Content Root.vhd.identity
Write-Host "A16DBG:G1: win-deploy DONE backup=Root.vhd.bak.$ts" -ForegroundColor Green
