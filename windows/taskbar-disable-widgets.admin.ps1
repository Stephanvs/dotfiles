. "$PSScriptRoot/_helpers.ps1"

Assert-Administrator

$widgetsDisabled = 0
$widgetsEnabled = 1

Set-RegistryValueIfDifferent `
  -Path 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests' `
  -Name 'value' `
  -Value $widgetsDisabled `
  -PropertyType DWord | Out-Null

Set-RegistryValueIfDifferent `
  -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' `
  -Name 'AllowNewsAndInterests' `
  -Value $widgetsDisabled `
  -PropertyType DWord | Out-Null
