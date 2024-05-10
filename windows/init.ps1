Set-Alias pbcopy Set-Clipboard
Set-Alias pbpaste Get-Clipboard
Set-Alias pb-copy Set-Clipboard
Set-Alias pb-paste Get-Clipboard

function Get-AllItems { & eza --icons --group-directories-first --sort size --all --no-filesize --no-permissions --no-time --no-quotes }


Set-Alias -Name l -Value Get-AllItems -Force -Scope Global
