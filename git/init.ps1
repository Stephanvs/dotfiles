[CmdletBinding()]
Param(
)

function Get-GitStatus { & git status }
function Set-GitCommit { & git commit -m $args }
function Set-GitAddAll { & git add --all }
functino Set-GitPush { & git push }

Write-Verbose "Setting git aliases:"

Set-Alias -Name gs -Value Get-GitStatus -Force -Scope Global
Set-Alias -Name gcm -Value Set-GitCommit -Force -Scope Global
Set-Alias -Name gaa -Value Set-GitAddAll -Force -Scope Global
Set-Alias -Name gp -Value Set-GitPush -Force -Scope Global

Write-Verbose "Git aliases installed."