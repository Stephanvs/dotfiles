$taskName = 'scoop-backup'
$launcherPath = Join-Path (Split-Path -Path $PSScriptRoot -Parent) 'windows\run-hidden.vbs'
$taskCommand = "wscript.exe //B //Nologo `"$launcherPath`" --cwd `"$PSScriptRoot`" `"pwsh.exe`" `"-WindowStyle`" `"Hidden`" `"-NoProfile`" `"-ExecutionPolicy`" `"Bypass`" `"-File`" `"backup-scoop.ps1`""

$arguments = @(
  '/Create'
  '/TN', $taskName
  '/TR', $taskCommand
  '/SC', 'DAILY'
  '/ST', '00:00'
  '/F'
)

& schtasks.exe @arguments

if ($LASTEXITCODE -ne 0) {
  throw "Failed to register scheduled task '$taskName'."
}
