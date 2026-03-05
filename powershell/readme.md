# Install Microsoft PowerShell Core
winget install Microsoft.PowerShell --silent

# Newer version of PSReadLine is required for auto completion
Install-Module -Name PSReadLine -AllowPrerelease -Force

Install-Module z -AllowClobber
