$log = "C:\ProgramData\BlueStacks_nxt\Engine\Tiramisu64\Logs\BstkCore.log"
$lines = Get-Content $log
Write-Output "Total lines: $($lines.Count)"
# Show all Guest Log messages (these are from the VM guest to host)
Write-Output "`n=== ALL Guest Log messages ==="
foreach ($line in $lines) {
    if ($line -match "Guest Log") {
        Write-Output $line
    }
}
# Show state changes
Write-Output "`n=== VM State Changes ==="
foreach ($line in $lines) {
    if ($line -match "Changing the VM state|Console.*state") {
        Write-Output $line
    }
}
# Show any errors or exceptions
Write-Output "`n=== Errors ==="
foreach ($line in $lines) {
    if ($line -match "error|Error|ERROR|panic|Panic|PANIC|Call Trace|RIP:|fault|Fault") {
        Write-Output $line
    }
}
# Show lines with timestamps between 3s and 28s
Write-Output "`n=== Timeline 3-28s (every 10th line) ==="
$count = 0
foreach ($line in $lines) {
    if ($line -match "^00:00:(0[3-9]|1[0-9]|2[0-8])") {
        $count++
        if ($count % 10 -eq 0) { Write-Output $line }
    }
}
Write-Output "`n=== Lines 28-30s (around reset) ==="
foreach ($line in $lines) {
    if ($line -match "^00:00:2[7-9]|^00:00:3[0-2]") {
        Write-Output $line
    }
}
