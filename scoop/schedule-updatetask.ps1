$taskName = 'scoop-update'
$launcherPath = Join-Path (Split-Path -Path $PSScriptRoot -Parent) 'windows\run-hidden.vbs'
$startTime = '00:00'
$taskCommand = "wscript.exe //B //Nologo `"$launcherPath`" --cwd `"$PSScriptRoot`" `"pwsh.exe`" `"-WindowStyle`" `"Hidden`" `"-NoProfile`" `"-NonInteractive`" `"-ExecutionPolicy`" `"Bypass`" `"-File`" `"scoop-update-all.ps1`""

$arguments = @(
  '/Create'
  '/TN', $taskName
  '/TR', $taskCommand
  '/SC', 'HOURLY'
  '/MO', '1'
  '/ST', $startTime
  '/F'
)

& schtasks.exe @arguments

if ($LASTEXITCODE -ne 0) {
  throw "Failed to register scheduled task '$taskName'."
}
