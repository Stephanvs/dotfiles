Import-Module -Name "$PSScriptRoot\..\lib\Symlink.psm1"

New-Symlink -SourcePath "$PSScriptRoot/settings.json" -TargetPath "$env:LOCALAPPDATA/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json" -Label 'Windows Terminal settings link'
