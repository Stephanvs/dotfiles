# Create Symbolic link for powershell profile
New-Item -ItemType SymbolicLink -Path $PROFILE -Target $PSScriptRoot/profile.ps1 -Force > $null
