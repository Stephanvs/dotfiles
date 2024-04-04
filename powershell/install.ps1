# Create Symbolic link for powershell profile
sudo New-Item -ItemType SymbolicLink -Path $PROFILE -Target $PSScriptRoot/profile.ps1 -Force | Out-Null
