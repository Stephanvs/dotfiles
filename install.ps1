[CmdletBinding()] param ()

$nl = [Environment]::NewLine
$DOTFILES="$HOME/dotfiles"
$Source = "$DOTFILES\*"

# Install scoop first
& ./scoop/install.ps1

# Ignore current file
$Ignored = @(
  (Get-Item -LiteralPath "$PSScriptRoot/install.ps1").FullName,
  (Get-Item -LiteralPath "$PSScriptRoot/scoop/install.ps1").FullName
)
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
