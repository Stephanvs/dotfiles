sudo New-Item -ItemType SymbolicLink `
  -Path $HOME/.config/ncspot/config.toml `
  -Target $PSScriptRoot/config.toml -Force | Out-Null

