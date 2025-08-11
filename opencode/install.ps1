Remove-Item $HOME\.config\opencode -Recurse -Force
New-Item -ItemType SymbolicLink -Path $HOME\.config\opencode -Target $PSScriptRoot -Force | Out-Null

