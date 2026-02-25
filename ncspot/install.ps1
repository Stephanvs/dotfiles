Import-Module -Name "$PSScriptRoot\..\lib\Symlink.psm1"

New-Symlink -SourcePath "$PSScriptRoot/config.toml" -TargetPath "$HOME/.config/ncspot/config.toml" -Label 'Ncspot config link'

