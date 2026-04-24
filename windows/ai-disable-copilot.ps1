. "$PSScriptRoot/_helpers.ps1"

$buttonHidden = 0
$buttonShown = 1
$copilotDisabled = 1
$copilotEnabled = 0
$copilotPackageName = 'Microsoft.Copilot'

$changes = @(
  @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'ShowCopilotButton'; Value = $buttonHidden },
  @{ Path = 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot'; Name = 'TurnOffWindowsCopilot'; Value = $copilotDisabled }
)

foreach ($change in $changes) {
  Set-RegistryValueIfDifferent -Path $change.Path -Name $change.Name -Value $change.Value -PropertyType DWord | Out-Null
}

Remove-AppxPackageIfInstalled -Name $copilotPackageName | Out-Null
