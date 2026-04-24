. "$PSScriptRoot/_helpers.ps1"

$disabled = 0
$enabled = 1

$changes = @(
  @{ Path = 'HKCU:\System\GameConfigStore'; Name = 'GameDVR_Enabled'; Value = $disabled },
  @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR'; Name = 'AppCaptureEnabled'; Value = $disabled }
)

foreach ($change in $changes) {
  Set-RegistryValueIfDifferent -Path $change.Path -Name $change.Name -Value $change.Value -PropertyType DWord | Out-Null
}
