$taskName = "scoop-backup"
$task = Get-ScheduledTaskInfo -TaskName $taskName -ErrorAction SilentlyContinue

if ($task) {
  Write-Verbose "Task '$taskName' already registered, exiting..."
  return
}

Write-Host "Task '$taskName' not registered, creating now..."

$wd = Resolve-Path .

$trigger = New-ScheduledTaskTrigger -AtLogOn
$action = New-ScheduledTaskAction -WorkingDirectory (Resolve-Path .) -Execute  "pwsh -wd $wd -c ./backup-scoop.ps1"
$user = whoami

Register-ScheduledTask -TaskName $taskName `
  -Trigger $trigger `
  -Action $action `
  -User $user

Write-Debug "Task '$taskName' scheduled to run on LogOn time"