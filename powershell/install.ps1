Install-Module -Name Terminal-Icons -Repository PSGallery

New-Item -ItemType SymbolicLink -Path ./profile.ps1 -Target $PROFILE
