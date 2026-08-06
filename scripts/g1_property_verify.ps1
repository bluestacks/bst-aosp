# G1 Layer2: verify BlueStacks data property files against the running guest.
param(
    [string]$AdbExe = "C:\Program Files\BlueStacks_nxt\HD-Adb.exe",
    [string]$Serial = "127.0.0.1:5556",
    [switch]$StrictMutable,
    [switch]$CheckOnly
)

$ErrorActionPreference = "Stop"
$propertyFiles = @(
    "/data/.bluestacks.prop",
    "/data/.bstconf.prop",
    "/data/.vendor.prop",
    "/data/.additional_system.prop"
)

if (-not (Test-Path $AdbExe)) { throw "HD-Adb missing: $AdbExe" }
if ($CheckOnly) {
    Write-Host "A16DBG:ANDROID16: property-verify CHECK OK; guest was not queried"
    exit 0
}

function Invoke-Adb {
    param([string[]]$Arguments)
    $output = @(& $AdbExe -s $Serial @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "HD-Adb failed ($LASTEXITCODE): $($Arguments -join ' ')`n$($output -join "`n")"
    }
    return $output
}

function ConvertFrom-PropertyFile {
    param([string]$Path, [string[]]$Lines)
    $properties = [ordered]@{}
    foreach ($rawLine in $Lines) {
        $line = $rawLine.TrimEnd("`r")
        if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith("#")) { continue }
        $separator = $line.IndexOf("=")
        if ($separator -le 0) { throw "Invalid property line in ${Path}: $line" }
        $name = $line.Substring(0, $separator).Trim()
        $value = $line.Substring($separator + 1)
        if ($properties.Contains($name)) { throw "Duplicate property in ${Path}: $name" }
        $properties[$name] = $value
    }
    return $properties
}

function ConvertFrom-GetProp {
    param([string[]]$Lines)
    $properties = @{}
    foreach ($rawLine in $Lines) {
        $line = $rawLine.TrimEnd("`r")
        if ($line -match '^\[([^]]+)\]: \[(.*)\]$') {
            $properties[$Matches[1]] = $Matches[2]
        }
    }
    return $properties
}

Write-Host "A16DBG:G1: property-verify start serial=$Serial"
Invoke-Adb -Arguments @("get-state") | Out-Null

$fileProperties = [ordered]@{}
try {
    # A13 hides bst.* from toolbox getprop unless this diagnostic switch is enabled.
    Invoke-Adb -Arguments @("shell", "setprop bst.debug.show_prop 1") | Out-Null

    foreach ($path in $propertyFiles) {
        $lines = Invoke-Adb -Arguments @("shell", "su -c 'test -r $path && cat $path'")
        $fileProperties[$path] = ConvertFrom-PropertyFile -Path $path -Lines $lines
    }

    $runtime = ConvertFrom-GetProp -Lines (Invoke-Adb -Arguments @("shell", "getprop"))
    if ($runtime.Count -eq 0) { throw "getprop returned no parseable properties" }

    $labelLines = Invoke-Adb -Arguments @(
        "shell",
        "su -c 'ls -lZ $($propertyFiles -join ' ') 2>&1'"
    )
    $unlabeled = @($labelLines | Select-String -SimpleMatch "u:object_r:unlabeled:s0")

    $missing = @()
    $readonlyMismatch = @()
    $criticalMismatch = @()
    $mutableMismatch = @()
    $exact = 0

    foreach ($path in $propertyFiles) {
        foreach ($entry in $fileProperties[$path].GetEnumerator()) {
            $name = [string]$entry.Key
            $expected = [string]$entry.Value
            if (-not $runtime.ContainsKey($name)) {
                $missing += "$path :: $name=$expected"
                continue
            }
            $actual = [string]$runtime[$name]
            if ($actual -ceq $expected) {
                $exact++
            } elseif ($name.StartsWith("ro.")) {
                $readonlyMismatch += "$path :: $name expected=[$expected] actual=[$actual]"
            } elseif ($name -eq "bst.max_fps") {
                $criticalMismatch += "$path :: $name expected=[$expected] actual=[$actual]"
            } else {
                $mutableMismatch += "$path :: $name expected=[$expected] actual=[$actual]"
            }
        }
    }

    Write-Host "=== G1 property verification ==="
    foreach ($path in $propertyFiles) {
        Write-Host ("  [FILE] {0}: {1} properties" -f $path, $fileProperties[$path].Count)
    }
    $labelLines | ForEach-Object { Write-Host "  [LABEL] $_" }
    Write-Host "  exact=$exact missing=$($missing.Count) ro_mismatch=$($readonlyMismatch.Count) critical_mismatch=$($criticalMismatch.Count) mutable_mismatch=$($mutableMismatch.Count)"

    foreach ($item in $mutableMismatch) { Write-Warning "Runtime-updated mutable property: $item" }
    foreach ($item in $missing) { Write-Error "Missing runtime property: $item" -ErrorAction Continue }
    foreach ($item in $readonlyMismatch) { Write-Error "Read-only override mismatch: $item" -ErrorAction Continue }
    foreach ($item in $criticalMismatch) { Write-Error "Critical property mismatch: $item" -ErrorAction Continue }
    foreach ($item in $unlabeled) { Write-Error "Unlabeled property file: $item" -ErrorAction Continue }

    $failureCount = $missing.Count + $readonlyMismatch.Count + $criticalMismatch.Count + $unlabeled.Count
    if ($StrictMutable) { $failureCount += $mutableMismatch.Count }
    if ($failureCount -gt 0) { throw "Property verification failed with $failureCount blocking finding(s)" }

    Write-Host "A16DBG:G1: property-verify PASS"
} finally {
    try {
        Invoke-Adb -Arguments @("shell", "setprop bst.debug.show_prop 0") | Out-Null
    } catch {
        Write-Warning "Could not restore bst.debug.show_prop=0: $_"
    }
}

exit 0
