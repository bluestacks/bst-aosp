# =============================================================================
# win-replace-tiramisu64.ps1 — 替换 Windows BlueStacks_nxt Tiramisu64 镜像
# =============================================================================
# 从 clouddev scp Root.vhd + fastboot.vdi (UUID 已匹配 .bstk) 替换到 Engine\Tiramisu64
# 旧文件备份为 .bak.<时间戳>
#
# 用法 (管理员 PowerShell):
#   .\win-replace-tiramisu64.ps1                    # 默认从 clouddev 拉
#   .\win-replace-tiramisu64.ps1 -SkipDownload       # 仅替换本地已有 .new 文件
# =============================================================================
param(
    [string]$CloudHost = "markxu@172.16.6.191",
    [string]$RemotePkg = "~/releases/Tiramisu64/bst-v5.22.210_Tiramisu64-local",
    [string]$EngineDir = "C:\ProgramData\BlueStacks_nxt\Engine\Tiramisu64",
    [switch]$SkipDownload
)

$ErrorActionPreference = "Stop"
Set-Location $EngineDir

Write-Host "=== 1. 停止 BlueStacks (确保 VBox 没锁文件) ===" -ForegroundColor Cyan
Get-Process -Name "HD-Player","BstkSVC","BstkVMMgr" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

if (-not $SkipDownload) {
    Write-Host "=== 2. 从 clouddev scp (UUID 已匹配 .bstk) ===" -ForegroundColor Cyan
    Remove-Item Root.vhd.new, fastboot.vdi.new -Force -ErrorAction SilentlyContinue
    & scp "${CloudHost}:$RemotePkg/Root.vhd" "Root.vhd.new"
    & scp "${CloudHost}:$RemotePkg/fastboot.vdi" "fastboot.vdi.new"
}

Write-Host "=== 3. 验证下载 ===" -ForegroundColor Cyan
foreach ($f in @("Root.vhd.new","fastboot.vdi.new")) {
    if (-not (Test-Path $f)) { throw "$f 不存在, scp 失败" }
}
$rootSize = (Get-Item "Root.vhd.new").Length
if ($rootSize -lt 1GB) { throw "Root.vhd.new 太小 ($rootSize), 可能损坏" }

Write-Host "=== 4. 备份旧文件 ===" -ForegroundColor Cyan
$ts = Get-Date -Format "yyyyMMdd-HHmm"
Copy-Item Root.vhd "Root.vhd.bak.$ts" -Force -ErrorAction SilentlyContinue
Copy-Item fastboot.vdi "fastboot.vdi.bak.$ts" -Force -ErrorAction SilentlyContinue
Write-Host "备份: Root.vhd.bak.$ts, fastboot.vdi.bak.$ts"

Write-Host "=== 5. 替换 ===" -ForegroundColor Cyan
Move-Item Root.vhd.new Root.vhd -Force
Move-Item fastboot.vdi.new fastboot.vdi -Force

Write-Host "=== 6. 最终状态 ===" -ForegroundColor Cyan
Get-ChildItem Root.vhd, fastboot.vdi | Format-Table Name, Length, LastWriteTime

Write-Host ""
Write-Host "✅ 替换完成。启动测试:" -ForegroundColor Green
Write-Host '   & "C:\Program Files\BlueStacks_nxt\HD-Player.exe" --instance Tiramisu64' -ForegroundColor Yellow
Write-Host ""
Write-Host "回退: Move-Item Root.vhd.bak.$ts Root.vhd -Force"
