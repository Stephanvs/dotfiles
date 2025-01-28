New-Item -ItemType SymbolicLink `
  -Path $HOME\applications.yaml `
  -Target $PSScriptRoot\applications.yaml -Force | Out-Null

New-Item -ItemType SymbolicLink `
  -Path $HOME\komorebi.ahk `
  -Target $PSScriptRoot\komorebi.ahk -Force | Out-Null

New-Item -ItemType SymbolicLink `
  -Path $HOME\komorebi.json `
  -Target $PSScriptRoot\komorebi.json -Force | Out-Null
