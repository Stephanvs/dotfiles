New-Item -ItemType SymbolicLink `
  -Path $HOME\applications.json `
  -Target $PSScriptRoot\applications.json -Force | Out-Null

New-Item -ItemType SymbolicLink `
  -Path $HOME\komorebi.ahk `
  -Target $PSScriptRoot\komorebi.ahk -Force | Out-Null

New-Item -ItemType SymbolicLink `
  -Path $HOME\komorebi.json `
  -Target $PSScriptRoot\komorebi.json -Force | Out-Null
