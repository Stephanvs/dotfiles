Import-Module -Name "$PSScriptRoot\..\lib\Symlink.psm1"

New-Symlink -SourcePath "$PSScriptRoot/gitconfig" -TargetPath "$HOME/.gitconfig" -Label 'Git config link'
New-Symlink -SourcePath "$PSScriptRoot/gitignore" -TargetPath "$HOME/.gitignore" -Label 'Git ignore link'
