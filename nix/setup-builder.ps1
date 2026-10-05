[CmdletBinding()]
param(
    [string] $Name = 'NixOS-Rehearsal',
    [string] $Directory = 'E:\VMs\NixOS-Rehearsal'
)

$ErrorActionPreference = 'Stop'
$release = '2605.7.2'
$sha256 = 'e7180ad555fdcb8e1e057e2ef056de467603a5e502ff8531053738371be3f6b9'
$directoryPath = [IO.Path]::GetFullPath($Directory).TrimEnd('\')

$existing = Get-ChildItem 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss' |
    Get-ItemProperty | Where-Object DistributionName -EQ $Name
if ($existing) {
    $existingPath = $existing.BasePath -replace '^\\\\\?\\', ''
    if ($existingPath.TrimEnd('\') -ne $directoryPath) {
        throw "WSL distribution '$Name' already exists at '$existingPath'. Choose a different name."
    }
} else {
    if ((Test-Path -LiteralPath $directoryPath) -and
        (Get-ChildItem -LiteralPath $directoryPath -Force | Select-Object -First 1)) {
        throw "The destination must be empty: $directoryPath"
    }
    $drive = Get-PSDrive -Name ([IO.Path]::GetPathRoot($directoryPath).Substring(0, 1))
    if ($drive.Free -lt 40GB) {
        throw 'Keep at least 40 GB free on the destination drive for the builder and VM.'
    }

    $downloadDirectory = Join-Path ([IO.Path]::GetDirectoryName($directoryPath)) 'downloads'
    New-Item -ItemType Directory -Path $downloadDirectory -Force | Out-Null
    $archive = Join-Path $downloadDirectory "nixos-$release-x86_64.wsl"
    if (-not (Test-Path -LiteralPath $archive)) {
        Invoke-WebRequest -Uri "https://github.com/nix-community/NixOS-WSL/releases/download/$release/nixos.wsl" -OutFile $archive
    }
    if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant() -ne $sha256) {
        throw "Checksum mismatch for $archive. No distribution was imported."
    }

    wsl --import $Name $directoryPath $archive --version 2
    if ($LASTEXITCODE -ne 0) { throw 'WSL import failed.' }
}

wsl -d $Name -u root -- sh -c 'nix --version; test -r /dev/kvm && test -w /dev/kvm'
if ($LASTEXITCODE -ne 0) {
    throw 'The builder cannot access /dev/kvm. Nested virtualization must be available before running the VM.'
}
Write-Host "Builder ready: wsl -d $Name"
