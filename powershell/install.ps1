# Install Terminal Icons
Install-Module -Name Terminal-Icons -Repository PSGallery

# Install OhMyPosh
winget install JanDeDobbeleer.OhMyPosh

# Create Symbolic link for powershell profile
New-Item -ItemType SymbolicLink -Path ./profile.ps1 -Target $PROFILE
