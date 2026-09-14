[CmdletBinding()]
Param(
)

function Start-OpenCode { & opencode2 --auto }

Set-Alias -Name oc -Value Start-OpenCode -Force -Scope Global

$env:OTUI_USE_ALTERNATE_SCREEN = '0'

# Persist this as a Windows user environment variable for programs launched later.
if ([Environment]::GetEnvironmentVariable('OTUI_USE_ALTERNATE_SCREEN', 'User') -ne '0') {
  [Environment]::SetEnvironmentVariable('OTUI_USE_ALTERNATE_SCREEN', '0', 'User')
}
