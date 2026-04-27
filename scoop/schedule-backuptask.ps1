$taskName = 'scoop-backup'
$scriptPath = Join-Path $PSScriptRoot 'backup-scoop.ps1'
$taskCommand = "pwsh.exe -NoProfile -ExecutionPolicy Bypass -WorkingDirectory `"$PSScriptRoot`" -File `"$scriptPath`""

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
