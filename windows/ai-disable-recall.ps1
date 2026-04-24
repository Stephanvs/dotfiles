. "$PSScriptRoot/_helpers.ps1"

$analysisDisabled = 1
$analysisEnabled = 0

Set-RegistryValueIfDifferent `
  -Path 'HKCU:\Software\Policies\Microsoft\Windows\WindowsAI' `
  -Name 'DisableAIDataAnalysis' `
  -Value $analysisDisabled `
  -PropertyType DWord | Out-Null
