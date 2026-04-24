. "$PSScriptRoot/_helpers.ps1"

$disabled = 0
$enabled = 1

$changes = @(
  @{ Name = 'SubscribedContent-338387Enabled'; Value = $disabled },
  @{ Name = 'RotatingLockScreenOverlayEnabled'; Value = $disabled }
)

foreach ($change in $changes) {
  Set-RegistryValueIfDifferent `
    -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' `
    -Name $change.Name `
    -Value $change.Value `
    -PropertyType DWord | Out-Null
}
