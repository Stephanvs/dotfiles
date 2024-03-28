[CmdletBinding()]
Param(
)

function Start-Lazygit { & lazygit }

Set-Alias -Name lg -Value Start-Lazygit -Force -Scope Global

