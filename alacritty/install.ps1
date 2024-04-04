Write-Verbose "Creating symbolic link for alacritty config from $PSScriptRoot\config to %APPDATA%\alacritty\alacritty.yml"
sudo New-Item -ItemType SymbolicLink -Path $env:APPDATA\alacritty\alacritty.yml -Target $PSScriptRoot\alacritty.windows.yml -Force | Out-Null
