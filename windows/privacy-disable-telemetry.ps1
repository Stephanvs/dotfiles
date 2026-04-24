. "$PSScriptRoot/_helpers.ps1"

$disabled = 0
$enabled = 1
$restrict = 1
$allow = 0

$changes = @(
  @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo'; Name = 'Enabled'; Value = $disabled },
  @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy'; Name = 'TailoredExperiencesWithDiagnosticDataEnabled'; Value = $disabled },
  @{ Path = 'HKCU:\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy'; Name = 'HasAccepted'; Value = $disabled },
  @{ Path = 'HKCU:\Software\Microsoft\Input\TIPC'; Name = 'Enabled'; Value = $disabled },
  @{ Path = 'HKCU:\Software\Microsoft\InputPersonalization'; Name = 'RestrictImplicitInkCollection'; Value = $restrict },
  @{ Path = 'HKCU:\Software\Microsoft\InputPersonalization'; Name = 'RestrictImplicitTextCollection'; Value = $restrict },
  @{ Path = 'HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore'; Name = 'HarvestContacts'; Value = $allow },
  @{ Path = 'HKCU:\Software\Microsoft\Personalization\Settings'; Name = 'AcceptedPrivacyPolicy'; Value = $disabled },
  @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'Start_TrackProgs'; Value = $disabled },
  @{ Path = 'HKCU:\SOFTWARE\Microsoft\Siuf\Rules'; Name = 'NumberOfSIUFInPeriod'; Value = $disabled }
)

foreach ($change in $changes) {
  Set-RegistryValueIfDifferent -Path $change.Path -Name $change.Name -Value $change.Value -PropertyType DWord | Out-Null
}

Remove-RegistryValueIfExists -Path 'HKCU:\SOFTWARE\Microsoft\Siuf\Rules' -Name 'PeriodInNanoSeconds' | Out-Null
