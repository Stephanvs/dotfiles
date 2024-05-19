Invoke-Command {reg import ./keyboard-rate.reg *>&1 | Out-Null}

& ./Remove-StartMenuWidgets.ps1
& ./left-align-start-menu.ps1
& ./Decrap.ps1

& ./Install-Apps.ps1
