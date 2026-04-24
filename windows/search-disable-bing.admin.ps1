. "$PSScriptRoot/_helpers.ps1"

Assert-Administrator

$cortanaDisabled = 0
$cortanaEnabled = 1

$changes = @(
  @{ Name = 'AllowCortana'; Value = $cortanaDisabled },
  @{ Name = 'CortanaConsent'; Value = $cortanaDisabled }
)

foreach ($change in $changes) {
  Set-RegistryValueIfDifferent `
    -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' `
    -Name $change.Name `
    -Value $change.Value `
    -PropertyType DWord | Out-Null
}
