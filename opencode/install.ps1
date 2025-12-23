Remove-Item $HOME\.config\opencode -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType SymbolicLink -Path $HOME\.config\opencode -Target $PSScriptRoot -Force | Out-Null

