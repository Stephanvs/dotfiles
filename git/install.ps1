sudo New-Item -ItemType SymbolicLink -Path $HOME\.gitconfig -Target $PSScriptRoot\gitconfig -Force | Out-Null
