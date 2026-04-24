$taskName = 'dotfiles-windows-install'
$repoRoot = Split-Path -Path $PSScriptRoot -Parent
$scriptPath = Join-Path $repoRoot 'install.ps1'
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$runLevelLimited = 'Limited'
$runLevelHighest = 'Highest'
$interactiveLogon = 'Interactive'
$serviceAccountLogon = 'ServiceAccount'
$midnight = '12:00AM'
$action = New-ScheduledTaskAction -Execute 'pwsh.exe' -WorkingDirectory $repoRoot -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
$trigger = New-ScheduledTaskTrigger -Daily -At $midnight
$principal = New-ScheduledTaskPrincipal -UserId $currentUser -LogonType $interactiveLogon -RunLevel $runLevelLimited

if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
  Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal | Out-Null
