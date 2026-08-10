# Android-16 Layer2: deploy the android_x86_64 Root.vhd to the Windows instance.
param(
    [string]$CloudHost = "markxu@172.16.6.191",
    [string]$RemotePkg = "~/releases/Baklava64/bst-v5.22.210_Baklava64-local",
    [string]$EngineDir = "C:\ProgramData\BlueStacks_nxt\Engine\Tiramisu64",
    [string]$ExpectedRootUuid = "54e9ad31-a169-4d5b-a0e0-705d62e96e71",
    [string]$ExpectedFastbootUuid = "91b80c95-aa7d-459d-93e4-c479f5babbb7",
    [switch]$CheckOnly
)
$ErrorActionPreference = "Stop"
if (-not (Test-Path $EngineDir)) { throw "EngineDir missing: $EngineDir" }
if ($CheckOnly) {
    if (-not (Get-Command scp -ErrorAction SilentlyContinue)) { throw "scp is unavailable" }
    Write-Host "A16DBG:ANDROID16: deploy CHECK OK; no process stopped and no file copied"
    exit 0
}

function Get-VhdFooterUuid {
    param([Parameter(Mandatory = $true)][string]$Path)

    $resolvedPath = (Resolve-Path -LiteralPath $Path).Path
    $stream = [System.IO.File]::OpenRead($resolvedPath)
    try {
        if ($stream.Length -lt 512) { throw "VHD is too small: $Path" }
        [void]$stream.Seek(-512, [System.IO.SeekOrigin]::End)
        $footer = [byte[]]::new(512)
        if ($stream.Read($footer, 0, $footer.Length) -ne $footer.Length) {
            throw "Unable to read VHD footer: $Path"
        }
    } finally {
        $stream.Dispose()
    }
    $cookie = [System.Text.Encoding]::ASCII.GetString($footer, 0, 8)
    if ($cookie -ne "conectix") { throw "Invalid VHD footer cookie: $Path" }
    $uuidBytes = [byte[]]::new(16)
    [Array]::Copy($footer, 68, $uuidBytes, 0, 16)
    return ([Guid]::new($uuidBytes)).ToString()
}

function Get-VdiUuid {
    param([Parameter(Mandatory = $true)][string]$Path)

    $stream = [System.IO.File]::OpenRead((Resolve-Path -LiteralPath $Path).Path)
    try {
        if ($stream.Length -lt 408) { throw "VDI is too small: $Path" }
        [void]$stream.Seek(64, [System.IO.SeekOrigin]::Begin)
        $signature = [byte[]]::new(4)
        if ($stream.Read($signature, 0, $signature.Length) -ne $signature.Length -or
            $signature[0] -ne 0x7f -or $signature[1] -ne 0x10 -or
            $signature[2] -ne 0xda -or $signature[3] -ne 0xbe) {
            throw "Invalid VDI signature: $Path"
        }
        [void]$stream.Seek(392, [System.IO.SeekOrigin]::Begin)
        $uuidBytes = [byte[]]::new(16)
        if ($stream.Read($uuidBytes, 0, $uuidBytes.Length) -ne $uuidBytes.Length) {
            throw "Unable to read VDI UUID: $Path"
        }
    } finally {
        $stream.Dispose()
    }
    return ([Guid]::new($uuidBytes)).ToString()
}

Set-Location $EngineDir
Write-Host "A16DBG:G1: win-deploy start" -ForegroundColor Cyan
Remove-Item Root.vhd.new -Force -ErrorAction SilentlyContinue
Remove-Item Root.vhd.identity.new -Force -ErrorAction SilentlyContinue
Remove-Item fastboot.vdi.new -Force -ErrorAction SilentlyContinue
& scp "${CloudHost}:${RemotePkg}/Root.vhd" "Root.vhd.new"
if ($LASTEXITCODE -ne 0) { throw "scp Root.vhd failed with exit $LASTEXITCODE" }
& scp "${CloudHost}:${RemotePkg}/Root.vhd.identity" "Root.vhd.identity.new"
if ($LASTEXITCODE -ne 0) { throw "scp Root.vhd.identity failed with exit $LASTEXITCODE" }
& scp "${CloudHost}:${RemotePkg}/fastboot.vdi" "fastboot.vdi.new"
if ($LASTEXITCODE -ne 0) { throw "scp fastboot.vdi failed with exit $LASTEXITCODE" }
if (-not (Test-Path "Root.vhd.new")) { throw "scp Root.vhd failed" }
if (-not (Test-Path "Root.vhd.identity.new")) { throw "scp identity failed" }
if (-not (Test-Path "fastboot.vdi.new")) { throw "scp fastboot.vdi failed" }
$sz = (Get-Item "Root.vhd.new").Length
# cont.21+: packed Root can be ~998MiB (still valid VHD); keep floor below historical ~1.0GiB
if ($sz -lt 800MB) { throw "Root.vhd.new too small: $sz" }
$identity = @{}
Get-Content "Root.vhd.identity.new" | ForEach-Object {
    if ($_ -match '^([^=]+)=(.*)$') { $identity[$Matches[1]] = $Matches[2] }
}
if (-not $identity["artifact_sha256"]) { throw "identity has no artifact_sha256" }
$localSha256 = (Get-FileHash "Root.vhd.new" -Algorithm SHA256).Hash.ToLowerInvariant()
if ($localSha256 -ne $identity["artifact_sha256"].ToLowerInvariant()) {
    throw "Root.vhd SHA256 mismatch: local=$localSha256 remote=$($identity['artifact_sha256'])"
}
if (-not $identity["fastboot_vdi_sha256"]) { throw "identity has no fastboot_vdi_sha256" }
$localFastbootSha256 = (Get-FileHash "fastboot.vdi.new" -Algorithm SHA256).Hash.ToLowerInvariant()
if ($localFastbootSha256 -ne $identity["fastboot_vdi_sha256"].ToLowerInvariant()) {
    throw "fastboot.vdi SHA256 mismatch: local=$localFastbootSha256 remote=$($identity['fastboot_vdi_sha256'])"
}
if (-not $identity["fastboot_vdi_uuid"]) { throw "identity has no fastboot_vdi_uuid" }
$localFastbootUuid = Get-VdiUuid -Path "fastboot.vdi.new"
if ($identity["fastboot_vdi_uuid"].ToLowerInvariant() -ne $ExpectedFastbootUuid.ToLowerInvariant() -or
    $localFastbootUuid.ToLowerInvariant() -ne $ExpectedFastbootUuid.ToLowerInvariant()) {
    throw "fastboot.vdi UUID mismatch: expected=$ExpectedFastbootUuid identity=$($identity['fastboot_vdi_uuid']) header=$localFastbootUuid"
}
if (-not $identity["vhd_uuid"]) { throw "identity has no vhd_uuid" }
$localVhdUuid = Get-VhdFooterUuid -Path "Root.vhd.new"
if ($identity["vhd_uuid"].ToLowerInvariant() -ne $ExpectedRootUuid.ToLowerInvariant() -or
    $localVhdUuid.ToLowerInvariant() -ne $ExpectedRootUuid.ToLowerInvariant()) {
    throw "Root.vhd UUID mismatch: expected=$ExpectedRootUuid identity=$($identity['vhd_uuid']) footer=$localVhdUuid"
}
$tiramisuPlayers = Get-CimInstance Win32_Process -Filter "Name = 'HD-Player.exe'" |
    Where-Object { $_.CommandLine -match '--instance\s+Tiramisu64(?:\s|$)' }
$tiramisuPlayers | ForEach-Object {
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 2
$ts = Get-Date -Format "yyyyMMdd-HHmm"
Copy-Item Root.vhd "Root.vhd.bak.$ts" -Force -ErrorAction SilentlyContinue
Copy-Item fastboot.vdi "fastboot.vdi.bak.$ts" -Force -ErrorAction SilentlyContinue
Move-Item Root.vhd.new Root.vhd -Force
Move-Item fastboot.vdi.new fastboot.vdi -Force
Move-Item Root.vhd.identity.new Root.vhd.identity -Force
Get-FileHash Root.vhd -Algorithm MD5 | Format-List
Get-Content Root.vhd.identity
Write-Host "A16DBG:G1: win-deploy DONE root_backup=Root.vhd.bak.$ts fastboot_backup=fastboot.vdi.bak.$ts" -ForegroundColor Green
