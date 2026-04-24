. "$PSScriptRoot/_helpers.ps1"

Assert-Administrator

$disabled = 0
$enabled = 1

Set-RegistryValueIfDifferent `
  -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' `
  -Name 'AllowGameDVR' `
  -Value $disabled `
  -PropertyType DWord | Out-Null
