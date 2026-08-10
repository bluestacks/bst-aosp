# Resolve Tiramisu64 shared-folder placeholders left by the local HD template.
param(
    [string]$EngineDir = "C:\ProgramData\BlueStacks_nxt\Engine\Tiramisu64",
    [string]$UserDataDir = "C:\ProgramData\BlueStacks_nxt\Engine\UserData",
    [switch]$CheckOnly
)

$ErrorActionPreference = "Stop"
$inputMapper = Join-Path $UserDataDir "InputMapper"
$sharedFolder = Join-Path $UserDataDir "SharedFolder"
$replacements = [ordered]@{
    "@@INPUT_MAPPER_FOLDER@@" = $inputMapper
    "@@BST_SHARED_FOLDER@@" = $sharedFolder
}
$configs = @(
    (Join-Path $EngineDir "Android.bstk.in"),
    (Join-Path $EngineDir "Tiramisu64.bstk")
)

foreach ($path in $configs) {
    if (-not (Test-Path -LiteralPath $path)) { throw "missing VM config: $path" }
}

if ($CheckOnly) {
    $unresolved = @()
    foreach ($path in $configs) {
        $text = [System.IO.File]::ReadAllText($path)
        foreach ($placeholder in $replacements.Keys) {
            if ($text.Contains($placeholder)) { $unresolved += "${path}:$placeholder" }
        }
    }
    if ($unresolved.Count) {
        throw "unresolved shared-folder placeholders: $($unresolved -join ', ')"
    }
    Write-Host "A16DBG:ANDROID16: shared-folder config CHECK OK"
    exit 0
}

$tiramisuPlayers = Get-CimInstance Win32_Process -Filter "Name = 'HD-Player.exe'" |
    Where-Object { $_.CommandLine -match '--instance\s+Tiramisu64(?:\s|$)' }
$tiramisuPlayers | ForEach-Object {
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 2

[System.IO.Directory]::CreateDirectory($inputMapper) | Out-Null
[System.IO.Directory]::CreateDirectory($sharedFolder) | Out-Null
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

foreach ($path in $configs) {
    $text = [System.IO.File]::ReadAllText($path)
    $updated = $text
    foreach ($entry in $replacements.GetEnumerator()) {
        $updated = $updated.Replace($entry.Key, $entry.Value)
    }
    if ($updated -ne $text) {
        Copy-Item -LiteralPath $path -Destination "$path.bak.$timestamp" -Force
        $temporary = "$path.new"
        [System.IO.File]::WriteAllText($temporary, $updated, $utf8NoBom)
        Move-Item -LiteralPath $temporary -Destination $path -Force
    }
    $readback = [System.IO.File]::ReadAllText($path)
    foreach ($entry in $replacements.GetEnumerator()) {
        if ($readback.Contains($entry.Key) -or -not $readback.Contains($entry.Value)) {
            throw "shared-folder config readback failed: $path"
        }
    }
}

Write-Host "A16DBG:G1: shared-folder config DONE backup=$timestamp" -ForegroundColor Green
