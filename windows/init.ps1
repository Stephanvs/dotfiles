Set-Alias pbcopy Set-Clipboard

function Get-AllItems { & ls }


Set-Alias -Name l -Value Get-AllItems -Force -Scope Global