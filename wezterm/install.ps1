Import-Module -Name "$PSScriptRoot\..\lib\Symlink.psm1" -Force

New-Symlink -SourcePath "$PSScriptRoot/wezterm.lua" -TargetPath "$HOME/.config/wezterm/wezterm.lua" -Label 'WezTerm config link'
