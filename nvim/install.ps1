$VIMHOME = "$env:LOCALAPPDATA\nvim"
# Create Symbolic link for powershell profile
Write-Verbose "Creating symbolic link for nvim config from $PSScriptRoot\config to $HOME\.config\nvim"
New-Item -ItemType SymbolicLink -Path $VIMHOME -Target $PSScriptRoot\config -Force > $null
