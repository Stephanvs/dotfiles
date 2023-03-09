# Create Symbolic link for powershell profile
Write-Verbose "Creating symbolic link for nvim config from $PSScriptRoot\config to $HOME\.config\nvim"
New-Item -ItemType SymbolicLink -Path $HOME\.config\nvim -Target $PSScriptRoot\config -Force > $null
