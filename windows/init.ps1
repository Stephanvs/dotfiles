Set-Alias pbcopy Set-Clipboard
Set-Alias pbpaste Get-Clipboard

function Get-AllItems { & ls }


Set-Alias -Name l -Value Get-AllItems -Force -Scope Global
