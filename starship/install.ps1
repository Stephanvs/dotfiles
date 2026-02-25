Import-Module -Name "$PSScriptRoot\..\lib\Symlink.psm1" -Force

New-Symlink -SourcePath "$PSScriptRoot/starship.toml" -TargetPath "$HOME/.config/starship.toml" -Label 'Starship config link'
