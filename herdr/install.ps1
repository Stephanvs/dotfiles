Import-Module -Name "$PSScriptRoot\..\lib\Symlink.psm1"

New-Symlink -SourcePath "$PSScriptRoot/config.toml" -TargetPath "$HOME/.config/herdr/config.toml" -Label 'Herdr config link'
