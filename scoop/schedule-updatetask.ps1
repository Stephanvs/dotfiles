$taskName = 'scoop-update'
$scriptPath = Join-Path $PSScriptRoot 'scoop-update-all.ps1'
$startTime = '00:00'
$taskCommand = "pwsh.exe -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""

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
