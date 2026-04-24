. "$PSScriptRoot/_helpers.ps1"

Assert-Administrator

$analysisDisabled = 1
$analysisEnabled = 0
$recallDisabled = 0
$recallEnabled = 1
$snapshotsDisabled = 1
$snapshotsEnabled = 0

$changes = @(
  @{ Name = 'DisableAIDataAnalysis'; Value = $analysisDisabled },
  @{ Name = 'AllowRecallEnablement'; Value = $recallDisabled },
  @{ Name = 'TurnOffSavingSnapshots'; Value = $snapshotsDisabled }
)

foreach ($change in $changes) {
  Set-RegistryValueIfDifferent `
    -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' `
    -Name $change.Name `
    -Value $change.Value `
    -PropertyType DWord | Out-Null
}
