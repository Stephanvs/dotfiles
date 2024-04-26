[CmdletBinding()]
Param(
)

function Invoke-Scoop { & scoop $args }

Write-Verbose "Setting scoop aliases:"

Set-Alias -Name brew -Value Invoke-Scoop -Force -Scope Global

Write-Verbose "Scoop aliases installed."
