sudo New-Item -ItemType SymbolicLink -Path $HOME\.config\wezterm\wezterm.lua -Target $PSScriptRoot\wezterm.lua -Force | Out-Null
