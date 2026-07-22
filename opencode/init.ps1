[CmdletBinding()]
Param(
)

function Start-OpenCode { & opencode --auto }

Set-Alias -Name oc -Value Start-OpenCode -Force -Scope Global
