Import-Module -Name "$PSScriptRoot\..\lib\Symlink.psm1"

Remove-Item -Force -Confirm:$false -Recurse "$env:LOCALAPPDATA/nvim" -ErrorAction SilentlyContinue
New-Symlink -SourcePath "$PSScriptRoot/nvchad" -TargetPath "$env:LOCALAPPDATA/nvim" -Label 'Neovim config link'
