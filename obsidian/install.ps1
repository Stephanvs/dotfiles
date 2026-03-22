Import-Module -Name "$PSScriptRoot\..\lib\Symlink.psm1"

$vaultPath = "$env:USERPROFILE\notes"
if (-not (Test-Path -LiteralPath $vaultPath)) {
    New-Item -ItemType Directory -Path $vaultPath -Force | Out-Null
    Write-Host "Created Obsidian Vault directory at $vaultPath"
}

New-Symlink -SourcePath "$PSScriptRoot" -TargetPath "$vaultPath\.obsidian" -Label 'Obsidian config link'
