[CmdletBinding()]
Param(
)

function Start-OpenCode { & opencode }

Set-Alias -Name oc -Value Start-OpenCode -Force -Scope Global
