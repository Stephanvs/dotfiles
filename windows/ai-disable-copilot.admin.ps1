. "$PSScriptRoot/_helpers.ps1"

Assert-Administrator

$copilotDisabled = 1
$copilotEnabled = 0

Set-RegistryValueIfDifferent `
  -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' `
  -Name 'TurnOffWindowsCopilot' `
  -Value $copilotDisabled `
  -PropertyType DWord | Out-Null
