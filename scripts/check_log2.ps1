# Check BstkCore.log.1 (previous boot) for comparison
$prevLog = "C:\ProgramData\BlueStacks_nxt\Engine\Tiramisu64\Logs\BstkCore.log.1"
if (Test-Path $prevLog) {
    Write-Output "=== BstkCore.log.1: searching for ACPI Reset / kernel messages ==="
    $lines = Get-Content $prevLog
    Write-Output "Total lines: $($lines.Count)"
    # Show timestamps around 15s mark and any ACPI reset
    foreach ($line in $lines) {
        if ($line -match "ACPI.*Reset|init|panic|Kernel|A16DBG|error|Error|Call Trace|RIP:") {
            Write-Output $line
        }
    }
}
Write-Output "`n=== BstkCore.log: timestamps dist ==="
$curLog = "C:\ProgramData\BlueStacks_nxt\Engine\Tiramisu64\Logs\BstkCore.log"
$curLines = Get-Content $curLog
Write-Output "Total lines: $($curLines.Count)"
# Show lines with timestamps between 2.9s and 15s
foreach ($line in $curLines) {
    if ($line -match "^00:00:(0[3-9]|1[0-5])") {
        Write-Output $line
    }
}
# Show all Guest Log messages
Write-Output "`n=== BstkCore.log: ALL Guest Log messages ==="
foreach ($line in $curLines) {
    if ($line -match "Guest Log") {
        Write-Output $line
    }
}
