# G1 Layer2: deploy bst_x86_64/qvirt Root.vhd to win Tiramisu64 instance
param(
    [string]$CloudHost = "markxu@172.16.6.191",
    [string]$RemotePkg = "~/releases/Baklava64/bst-v5.22.210_Baklava64-local",
    [string]$EngineDir = "C:\ProgramData\BlueStacks_nxt\Engine\Tiramisu64"
)
$ErrorActionPreference = "Stop"
if (-not (Test-Path $EngineDir)) { throw "EngineDir missing: $EngineDir" }
Set-Location $EngineDir
Write-Host "A16DBG:G1: win-deploy start" -ForegroundColor Cyan
Get-Process -Name "HD-Player","BstkSVC","BstkVMMgr" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Remove-Item Root.vhd.new -Force -ErrorAction SilentlyContinue
& scp "${CloudHost}:${RemotePkg}/Root.vhd" "Root.vhd.new"
if (-not (Test-Path "Root.vhd.new")) { throw "scp Root.vhd failed" }
$sz = (Get-Item "Root.vhd.new").Length
if ($sz -lt 1GB) { throw "Root.vhd.new too small: $sz" }
$ts = Get-Date -Format "yyyyMMdd-HHmm"
Copy-Item Root.vhd "Root.vhd.bak.$ts" -Force -ErrorAction SilentlyContinue
Move-Item Root.vhd.new Root.vhd -Force
Get-FileHash Root.vhd -Algorithm MD5 | Format-List
Write-Host "A16DBG:G1: win-deploy DONE backup=Root.vhd.bak.$ts" -ForegroundColor Green
