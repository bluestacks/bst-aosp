# Check for VBox.log files recursively
$logDir = "C:\ProgramData\BlueStacks_nxt\Engine\Tiramisu64\Logs"
Write-Output "=== Searching recursively for VBox*.log ==="
$vboxLogs = Get-ChildItem $logDir -Recurse -Filter "VBox*.log" -ErrorAction SilentlyContinue
foreach ($f in $vboxLogs) {
    Write-Output "=== $($f.FullName) ($($f.Length) bytes) ==="
    Get-Content $f.FullName -Tail 100
    Write-Output "---"
}

# Also check the full BstkCore.log for the latest boot
$coreLog = Join-Path $logDir "BstkCore.log"
if (Test-Path $coreLog) {
    Write-Output "`n=== BstkCore.log FULL (last 200 lines) ==="
    Get-Content $coreLog -Tail 200
}

# Check if any VM is still running
Write-Output "`n=== VBoxManage list runningvms ==="
& "C:\Program Files\BlueStacks_nxt\HD-VBoxHypervisor.exe" list runningvms 2>&1 | Select-Object -First 10
