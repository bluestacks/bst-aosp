# Reset Data.vhdx to clean G1 snapshot (discipline: after failed boot or before Layer2 verify)
param(
    [string]$EngineDir = "C:\ProgramData\BlueStacks_nxt\Engine\Tiramisu64",
    [string]$WipeName = "Data.vhdx.wipe20260717-141744",
    [switch]$CheckOnly
)
$ErrorActionPreference = "Stop"
$wipe = Join-Path $EngineDir $WipeName
if (-not (Test-Path $wipe)) { throw "missing wipe snapshot: $wipe" }
$data = Join-Path $EngineDir "Data.vhdx"
if ($CheckOnly) {
    Write-Host "A16DBG:ANDROID16: data-reset CHECK OK snapshot=$wipe; no process stopped and no file copied"
    exit 0
}
Get-Process -Name "HD-Player","BstkSVC","BstkVMMgr" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
$sourceHash = (Get-FileHash $wipe -Algorithm SHA256).Hash
Copy-Item $wipe $data -Force
$targetHash = (Get-FileHash $data -Algorithm SHA256).Hash
if ($sourceHash -ne $targetHash) {
    throw "Data.vhdx SHA256 mismatch after reset: source=$sourceHash target=$targetHash"
}
Get-FileHash $data -Algorithm SHA256 | Format-List
Write-Host "A16DBG:G1: Data reset to $WipeName OK" -ForegroundColor Green
