$logDir = "C:\ProgramData\BlueStacks_nxt\Engine\Tiramisu64\Logs"
$files = Get-ChildItem $logDir -Recurse -File | Sort-Object LastWriteTime -Descending | Select-Object -First 15
foreach ($f in $files) {
    $msg = "{0}`t{1}`t{2}" -f $f.LastWriteTime.ToString("HH:mm:ss"), $f.Length, $f.FullName
    Write-Output $msg
}
# Also show directory listing
Write-Output "`n=== Top-level Logs ==="
Get-ChildItem $logDir -Directory | ForEach-Object {
    Write-Output "DIR: $($_.Name) ($($_.LastWriteTime))"
    Get-ChildItem $_.FullName -File -Filter "*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 3 | ForEach-Object {
        Write-Output "  $($_.LastWriteTime) $($_.Length) $($_.Name)"
    }
}
