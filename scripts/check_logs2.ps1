# Refresh file listing - check for newer logs
$logDir = "C:\ProgramData\BlueStacks_nxt\Engine\Tiramisu64\Logs"
$files = Get-ChildItem $logDir -Recurse -File | Sort-Object LastWriteTime -Descending | Select-Object -First 10
foreach ($f in $files) {
    $msg = "{0}`t{1}`t{2}" -f $f.LastWriteTime.ToString("HH:mm:ss"), $f.Length, $f.FullName
    Write-Output $msg
}

Write-Output "`n=== Latest BstkCore.log first 20 lines (check if it has a new boot after reset) ==="
$curLog = Join-Path $logDir "BstkCore.log"
$lines = Get-Content $curLog
Write-Output "Total lines: $($lines.Count)"
# Show lines 1-20 to see VM creation
for ($i = 0; $i -lt [Math]::Min(20, $lines.Count); $i++) {
    Write-Output $lines[$i]
}
# Show last 50 lines to see what happens after reset
Write-Output "`n=== Last 50 lines ==="
for ($i = [Math]::Max(0, $lines.Count - 50); $i -lt $lines.Count; $i++) {
    Write-Output $lines[$i]
}
