Import-Module -Name "$PSScriptRoot\..\lib\Symlink.psm1"

New-Symlink -SourcePath "$PSScriptRoot/profile.ps1" -TargetPath "$([Environment]::GetFolderPath('MyDocuments'))/PowerShell/Microsoft.PowerShell_profile.ps1" -Label 'Profile link'
