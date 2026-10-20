param([Parameter(Mandatory=$true)][string]$Launch)
$ErrorActionPreference = 'Stop'
try {
  Add-Type -Path (Join-Path $PSScriptRoot 'guardian.cs')
  $spec = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Launch)) | ConvertFrom-Json
  exit [ACPJobGuardian]::Run($spec.commandLine, $spec.cwd, [uint32]$spec.parentPid)
} catch {
  [Console]::Error.WriteLine('Claude ACP Job Object guardian failed: ' + $_.Exception.Message)
  exit 126
}
