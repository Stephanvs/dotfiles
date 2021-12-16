[CmdletBinding()]
Param(
)

function Invoke-YarnStart { & yarn start }

Write-Verbose "Setting js aliases:"

Set-Alias -Name yas -Value Invoke-YarnStart -Force -Scope Global

Write-Verbose "js aliases installed."