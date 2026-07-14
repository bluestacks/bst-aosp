$log = "C:\ProgramData\BlueStacks_nxt\Engine\Tiramisu64\Logs\BstkCore.log"
$lines = Get-Content $log
Write-Output "Total: $($lines.Count) lines"
Write-Output "ACPI resets: $((Get-Content $log | Select-String 'ACPI.*Reset').Count)"
# Show all Guest Log messages
Write-Output "`n=== Guest Log ==="
foreach ($line in $lines) { if ($line -match "Guest Log") { Write-Output $line } }
# Show state changes
Write-Output "`n=== VM State ==="
foreach ($line in $lines) { if ($line -match "Changing.*state|Console.*state") { Write-Output $line } }
# Show last 20 lines
Write-Output "`n=== Last 20 ==="
for ($i = [Math]::Max(0, $lines.Count - 20); $i -lt $lines.Count; $i++) {
    Write-Output "$i : $($lines[$i])"
}
# Check VM process
Write-Output "`n=== VM process ==="
Get-Process -Name 'HD-Player' -ErrorAction SilentlyContinue | Select-Object Id,CPU,WorkingSet
