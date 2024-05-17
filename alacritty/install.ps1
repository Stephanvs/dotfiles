Write-Verbose "Creating symbolic link for alacritty config from $PSScriptRoot\config to %APPDATA%\alacritty\alacritty.windows.toml"
sudo New-Item -ItemType SymbolicLink -Path $env:APPDATA\alacritty\alacritty.toml -Target $PSScriptRoot\alacritty.windows.toml -Force | Out-Null
