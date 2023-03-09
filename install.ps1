[CmdletBinding()] param ()

$nl = [Environment]::NewLine
$DOTFILES="$HOME/dotfiles"
$Source = "$DOTFILES\*"

# Ignore current file
$Ignored = @((Get-ChildItem -Path $PSScriptRoot -File -Filter install.ps1).FullName) # Weird powershell hack to exclude current file from the install scripts.
Write-Debug "Ignored scripts: $Ignored"
$Scripts = Get-ChildItem $Source -File -Filter install.ps1 -Recurse
Write-Debug "Found scripts:$nl$($Scripts | Format-List -Property FullName | Out-String)"

# Discover 'install.ps1' files recursilvely and invoke them here
foreach ($Script in $Scripts) {

  if ($Script.FullName -In $Ignored) {
    Write-Warning "Skipping: $Script"
    continue
  }

  Write-Verbose "[-- Executing: $Script"
  & $Script
  Write-Verbose "--] Done"
}