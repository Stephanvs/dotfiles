[CmdletBinding()]
param(
    [ValidateSet('check', 'build', 'run', 'web', 'verify')]
    [string] $Action = 'check',
    [string] $Builder = 'NixOS-Rehearsal'
)
$ErrorActionPreference = 'Stop'
$repository = Split-Path $PSScriptRoot -Parent
$linuxRepository = wsl -d $Builder -u root -- wslpath -a $repository.Replace('\', '/')
if ($LASTEXITCODE -ne 0) { throw 'Could not resolve the repository in WSL. Check that the builder is installed.' }
$scriptCopy = Join-Path ([IO.Path]::GetTempPath()) "nixos-rehearse-$([guid]::NewGuid()).sh"
try {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'rehearse.sh') -Destination $scriptCopy
    $linuxScript = wsl -d $Builder -u root -- wslpath -a $scriptCopy.Replace('\', '/')
    if ($LASTEXITCODE -ne 0) { throw 'Could not resolve the temporary script in WSL.' }
    wsl -d $Builder -u root -- bash $linuxScript.Trim() $Action $linuxRepository.Trim()
    if ($LASTEXITCODE -ne 0) { throw "NixOS rehearsal action '$Action' failed." }
} finally {
    Remove-Item -LiteralPath $scriptCopy
}
