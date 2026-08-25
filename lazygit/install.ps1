Import-Module -Name "$PSScriptRoot\..\lib\Symlink.psm1"

New-Symlink -SourcePath "$PSScriptRoot/config.yml" -TargetPath "$env:LOCALAPPDATA/lazygit/config.yml" -Label 'Lazygit config link'
