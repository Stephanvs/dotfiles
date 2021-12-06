# Install Microsoft PowerShell Core
winget install Microsoft.PowerShell --silent

# Install Terminal Icons
Install-Module -Name Terminal-Icons -Repository PSGallery

# Newer version of PSReadLine is required for auto completion
Install-Module -Name PSReadLine -AllowPrerelease -Force

# Install OhMyPosh
winget install JanDeDobbeleer.OhMyPosh --silent

Install-Module z -AllowClobber

# Create Symbolic link for powershell profile
New-Item -ItemType SymbolicLink -Path $PROFILE -Target $PSScriptRoot/profile.ps1 -Force
