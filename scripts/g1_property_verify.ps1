# G1 Layer2: verify BlueStacks data property files against the running guest.
param(
    [string]$AdbExe = "C:\Program Files\BlueStacks_nxt\HD-Adb.exe",
    [string]$Serial,
    [string]$Instance = "Tiramisu64",
    [string]$BlueStacksConfig = "C:\ProgramData\BlueStacks_nxt\bluestacks.conf",
    [switch]$StrictMutable,
    [switch]$StrictReadOnly,
    [switch]$CheckOnly
)

$ErrorActionPreference = "Stop"
$propertyFiles = @(
    [pscustomobject]@{ Path = "/data/.bluestacks.prop"; Required = $true },
    [pscustomobject]@{ Path = "/data/.bstconf.prop"; Required = $true },
    [pscustomobject]@{ Path = "/data/.vendor.prop"; Required = $true },
    [pscustomobject]@{ Path = "/data/.additional_system.prop"; Required = $false }
)
$criticalExactNames = @(
    "bst.max_fps",
    "bst.shared_folders",
    "bst.wifi_mac_addr"
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

function Resolve-AdbSerial {
    if (-not [string]::IsNullOrWhiteSpace($Serial)) { return $Serial }

    if (Test-Path -LiteralPath $BlueStacksConfig) {
        $escapedInstance = [regex]::Escape($Instance)
        $statusPort = Get-Content -LiteralPath $BlueStacksConfig | ForEach-Object {
            if ($_ -match "^bst\.instance\.$escapedInstance\.status\.adb_port=`"(\d+)`"$") {
                $Matches[1]
            }
        } | Select-Object -Last 1
        if ($statusPort) {
            $configuredSerial = "127.0.0.1:$statusPort"
            $connectOutput = @(& $AdbExe connect $configuredSerial 2>&1)
            if ($LASTEXITCODE -ne 0) {
                throw "HD-Adb connect failed ($LASTEXITCODE): $configuredSerial`n$($connectOutput -join "`n")"
            }
            $stateOutput = @(& $AdbExe -s $configuredSerial get-state 2>&1)
            if ($LASTEXITCODE -ne 0 -or ($stateOutput -join "`n").Trim() -ne "device") {
                throw "Configured $Instance HD-Adb endpoint is not online: $configuredSerial"
            }
            return $configuredSerial
        }
    }

    $output = @(& $AdbExe devices 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "HD-Adb devices failed ($LASTEXITCODE):`n$($output -join "`n")"
    }
    $devices = @($output | ForEach-Object {
        if ($_ -match '^(\S+)\s+device(?:\s|$)') { $Matches[1] }
    })
    if ($devices.Count -eq 0) { throw "No online HD-Adb device found" }
    if ($devices.Count -gt 1) {
        throw "Multiple HD-Adb devices found; pass -Serial explicitly: $($devices -join ', ')"
    }
    return $devices[0]
}

function ConvertFrom-PropertyFile {
    param([string]$Path, [string[]]$Lines)
    $properties = [ordered]@{}
    $duplicates = @()
    foreach ($rawLine in $Lines) {
        $line = $rawLine.TrimEnd("`r")
        if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith("#")) { continue }
        $separator = $line.IndexOf("=")
        if ($separator -le 0) { throw "Invalid property line in ${Path}: $line" }
        $name = $line.Substring(0, $separator).Trim()
        $value = $line.Substring($separator + 1)
        if ($properties.Contains($name)) {
            $duplicates += [pscustomobject]@{
                Path = $Path
                Name = $name
                Previous = [string]$properties[$name]
                Current = $value
            }
        }
        $properties[$name] = $value
    }
    return [pscustomobject]@{ Properties = $properties; Duplicates = $duplicates }
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

$Serial = Resolve-AdbSerial
Write-Host "A16DBG:G1: property-verify start serial=$Serial"
Invoke-Adb -Arguments @("get-state") | Out-Null

$fileProperties = [ordered]@{}
try {
    $duplicateProperties = @()
    $missingFiles = @()
    foreach ($file in $propertyFiles) {
        $path = $file.Path
        $lines = Invoke-Adb -Arguments @(
            "shell",
            "if test -r $path; then cat $path; else echo __BST_PROPERTY_FILE_MISSING__; fi"
        )
        if ($lines -contains "__BST_PROPERTY_FILE_MISSING__") {
            if ($file.Required) { $missingFiles += $path }
            else { Write-Warning "Optional property file is absent: $path" }
            continue
        }
        $parsed = ConvertFrom-PropertyFile -Path $path -Lines $lines
        $fileProperties[$path] = $parsed.Properties
        $duplicateProperties += $parsed.Duplicates
    }

    # A13 hides bst.* only from bulk output. Named lookups are a runtime contract
    # used by mountsf, FPS configuration, and Wi-Fi identity consumers.
    Invoke-Adb -Arguments @("shell", "setprop bst.debug.show_prop 0") | Out-Null
    $exactLookupMismatch = @()
    foreach ($name in $criticalExactNames) {
        $expected = $null
        foreach ($path in $fileProperties.Keys) {
            if ($fileProperties[$path].Contains($name)) {
                $expected = [string]$fileProperties[$path][$name]
            }
        }
        $actual = ((Invoke-Adb -Arguments @("shell", "getprop", $name)) -join "`n").Trim()
        if ($null -eq $expected -or $actual -cne $expected) {
            $exactLookupMismatch += "$name expected=[$expected] actual=[$actual]"
        }
    }

    $hiddenRuntime = ConvertFrom-GetProp -Lines (Invoke-Adb -Arguments @("shell", "getprop"))
    $bulkVisibilityLeak = @($hiddenRuntime.Keys | Where-Object {
        ([string]$_).StartsWith("bst")
    })

    Invoke-Adb -Arguments @("shell", "setprop bst.debug.show_prop 1") | Out-Null
    $runtime = ConvertFrom-GetProp -Lines (Invoke-Adb -Arguments @("shell", "getprop"))
    if ($runtime.Count -eq 0) { throw "getprop returned no parseable properties" }

    $labelLines = Invoke-Adb -Arguments @(
        "shell",
        "ls -lZ $($fileProperties.Keys -join ' ') 2>&1"
    )
    $unlabeled = @($labelLines | Select-String -SimpleMatch "u:object_r:unlabeled:s0")

    $missing = @()
    $readonlyMismatch = @()
    $criticalMismatch = @()
    $mutableMismatch = @()
    $exact = 0

    foreach ($path in $fileProperties.Keys) {
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
    foreach ($path in $fileProperties.Keys) {
        Write-Host ("  [FILE] {0}: {1} properties" -f $path, $fileProperties[$path].Count)
    }
    $labelLines | ForEach-Object { Write-Host "  [LABEL] $_" }
    Write-Host "  missing_files=$($missingFiles.Count) duplicate_entries=$($duplicateProperties.Count) exact=$exact missing=$($missing.Count) exact_lookup_mismatch=$($exactLookupMismatch.Count) bulk_visibility_leak=$($bulkVisibilityLeak.Count) ro_mismatch=$($readonlyMismatch.Count) critical_mismatch=$($criticalMismatch.Count) mutable_mismatch=$($mutableMismatch.Count)"

    foreach ($path in $missingFiles) { Write-Error "Required property file is absent: $path" -ErrorAction Continue }
    foreach ($item in $duplicateProperties) {
        Write-Warning "Duplicate property (last value wins): $($item.Path) :: $($item.Name) previous=[$($item.Previous)] current=[$($item.Current)]"
    }
    foreach ($item in $mutableMismatch) { Write-Warning "Runtime-updated mutable property: $item" }
    foreach ($item in $missing) { Write-Error "Missing runtime property: $item" -ErrorAction Continue }
    foreach ($item in $exactLookupMismatch) { Write-Error "Exact property lookup mismatch: $item" -ErrorAction Continue }
    if ($bulkVisibilityLeak.Count -gt 0) {
        Write-Error "BlueStacks properties leaked into bulk getprop: $($bulkVisibilityLeak -join ', ')" -ErrorAction Continue
    }
    if ($readonlyMismatch.Count -gt 0) {
        $readonlyWriter = if ($StrictReadOnly) { "Error" } else { "Warning" }
        $readonlyMismatch | Select-Object -First 20 | ForEach-Object {
            if ($readonlyWriter -eq "Error") {
                Write-Error "Read-only template mismatch: $_" -ErrorAction Continue
            } else {
                Write-Warning "Read-only template mismatch: $_"
            }
        }
        if ($readonlyMismatch.Count -gt 20) {
            Write-Warning "$($readonlyMismatch.Count - 20) additional read-only template mismatches omitted"
        }
    }
    foreach ($item in $criticalMismatch) { Write-Error "Critical property mismatch: $item" -ErrorAction Continue }
    foreach ($item in $unlabeled) { Write-Warning "Externally generated property file is unlabeled: $item" }

    $failureCount = $missingFiles.Count + $missing.Count + $exactLookupMismatch.Count +
        $bulkVisibilityLeak.Count + $criticalMismatch.Count
    if ($StrictMutable) { $failureCount += $mutableMismatch.Count }
    if ($StrictReadOnly) { $failureCount += $readonlyMismatch.Count }
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
