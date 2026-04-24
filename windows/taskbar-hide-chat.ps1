. "$PSScriptRoot/_helpers.ps1"

$chatHidden = 0
$chatShown = 1
$meetNowHidden = 1
$meetNowShown = 0

$changes = @(
  @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'TaskbarMn'; Value = $chatHidden },
  @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'HideSCAMeetNow'; Value = $meetNowHidden }
)

foreach ($change in $changes) {
  Set-RegistryValueIfDifferent -Path $change.Path -Name $change.Name -Value $change.Value -PropertyType DWord | Out-Null
}
