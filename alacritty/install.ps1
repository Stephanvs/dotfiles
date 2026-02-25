Import-Module -Name "$PSScriptRoot\..\lib\Symlink.psm1"

New-Symlink -SourcePath "$PSScriptRoot/alacritty.windows.toml" -TargetPath "$env:APPDATA/alacritty/alacritty.toml" -Label 'Alacritty config link'
