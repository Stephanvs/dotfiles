[CmdletBinding()]
Param(
)

function Start-OpenCode { & opencode2 --auto }

Set-Alias -Name oc -Value Start-OpenCode -Force -Scope Global
