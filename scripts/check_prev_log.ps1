# Compare previous boot (log.1, 17:05, before APEX fix) vs current (log, 17:18, with APEX fix)
$prev = "C:\ProgramData\BlueStacks_nxt\Engine\Tiramisu64\Logs\BstkCore.log.1"
$cur = "C:\ProgramData\BlueStacks_nxt\Engine\Tiramisu64\Logs\BstkCore.log"

Write-Output "=== PREVIOUS BOOT (.log.1): Guest Log messages ==="
$prevLines = Get-Content $prev
foreach ($line in $prevLines) {
    if ($line -match "Guest Log|ACPI.*Reset|Changing the VM state") {
        Write-Output $line
    }
}

Write-Output "`n=== PREVIOUS BOOT: all timestamped lines 01-20s ==="
foreach ($line in $prevLines) {
    if ($line -match "^00:00:(0[1-9]|1[0-9]|20)") {
        Write-Output $line
    }
}

Write-Output "`n=== PREVIOUS BOOT: lines around 15s ==="
for ($i = 0; $i -lt $prevLines.Count; $i++) {
    if ($prevLines[$i] -match "^00:00:1[4-6]") {
        $start = [Math]::Max(0, $i - 3)
        $end = [Math]::Min($prevLines.Count - 1, $i + 3)
        for ($j = $start; $j -le $end; $j++) {
            Write-Output $prevLines[$j]
        }
        Write-Output "---"
    }
}
