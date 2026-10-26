$taskName = 'scoop-update'
$launcherPath = Join-Path (Split-Path -Path $PSScriptRoot -Parent) 'windows\run-hidden.vbs'
# Use Windows PowerShell so the updater can replace Scoop's pwsh installation.
$powershellPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$action = New-ScheduledTaskAction -Execute 'wscript.exe' -WorkingDirectory $PSScriptRoot -Argument "//B //Nologo `"$launcherPath`" --cwd `"$PSScriptRoot`" `"$powershellPath`" -WindowStyle Hidden -NoProfile -NonInteractive -ExecutionPolicy Bypass -File scoop-update-all.ps1"
$trigger = New-ScheduledTaskTrigger -Once -At ([DateTime]::Today) -RepetitionInterval (New-TimeSpan -Hours 1)
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$principal = New-ScheduledTaskPrincipal -UserId $currentUser -LogonType Interactive -RunLevel Limited

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Force -ErrorAction Stop | Out-Null
