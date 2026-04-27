wevtutil.exe sl 'Microsoft-Windows-TaskScheduler/Operational' /e:true

if ($LASTEXITCODE -ne 0) {
  throw 'Failed to enable Task Scheduler history.'
}
