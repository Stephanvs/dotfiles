Import-Module -Name "$PSScriptRoot\..\lib\Symlink.psm1"

New-Symlink -SourcePath "$PSScriptRoot/zen-keyboard-shortcuts.json" -TargetPath "$HOME/scoop/persist/zen-browser/profile/zen-keyboard-shortcuts.json" -Label 'Zen keyboard shortcuts link'
