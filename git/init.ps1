[CmdletBinding()]
Param(
)

function Get-GitStatus { & git status }
function Set-GitCommit { & git commit -m $args }

Write-Verbose "Setting git aliases:"

Set-Alias -Name gs -Value Get-GitStatus -Force -Scope Global
Set-Alias -Name gcm -Value Set-GitCommit -Force -Scope Global

Write-Verbose "Git aliases installed."