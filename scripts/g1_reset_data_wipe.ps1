# Reset Data.vhdx to clean G1 snapshot (discipline: after failed boot or before Layer2 verify)
param(
    [string]$EngineDir = "C:\ProgramData\BlueStacks_nxt\Engine\Tiramisu64",
    [string]$WipeName = "Data.vhdx.wipe20260717-141744"
)
$ErrorActionPreference = "Stop"
Get-Process -Name "HD-Player","BstkSVC","BstkVMMgr" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
$wipe = Join-Path $EngineDir $WipeName
if (-not (Test-Path $wipe)) { throw "missing wipe snapshot: $wipe" }
Copy-Item $wipe (Join-Path $EngineDir "Data.vhdx") -Force
Get-FileHash (Join-Path $EngineDir "Data.vhdx") -Algorithm MD5 | Format-List
Write-Host "A16DBG:G1: Data reset to $WipeName OK" -ForegroundColor Green
