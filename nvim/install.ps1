$VIMHOME = "$env:LOCALAPPDATA\nvim"

# nuke nvim directory
Remove-Item -Force -Confirm:$false -Recurse $VIMHOME

git clone https://github.com/NvChad/NvChad $VIMHOME --depth 1

# Create Symbolic link for powershell profile
Write-Verbose "Creating symbolic link for nvim custom from $PSScriptRoot\config to $VIMHOME"
New-Item -ItemType SymbolicLink -Path $VIMHOME\lua\custom -Target $PSScriptRoot\custom -Force > $null
