$taskName = 'dotfiles-windows-install'
$repoRoot = Split-Path -Path $PSScriptRoot -Parent
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$runLevelLimited = 'Limited'
$runLevelHighest = 'Highest'
$interactiveLogon = 'Interactive'
$serviceAccountLogon = 'ServiceAccount'
$midnight = '12:00AM'
$launcherPath = Join-Path $PSScriptRoot 'run-hidden.vbs'
$action = New-ScheduledTaskAction -Execute 'wscript.exe' -WorkingDirectory $repoRoot -Argument "//B //Nologo `"$launcherPath`" --cwd `"$repoRoot`" pwsh.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File install.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At $midnight
$principal = New-ScheduledTaskPrincipal -UserId $currentUser -LogonType $interactiveLogon -RunLevel $runLevelLimited

if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
  Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal | Out-Null
