. "$PSScriptRoot/_helpers.ps1"

Assert-Administrator

$requiredOnly = 0
$optionalAllowed = 1

$changes = @(
  @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection'; Name = 'AllowTelemetry'; Value = $requiredOnly },
  @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'; Name = 'PublishUserActivities'; Value = $requiredOnly },
  @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'PersonalizationReportingEnabled'; Value = $requiredOnly },
  @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'DiagnosticData'; Value = $requiredOnly }
)

foreach ($change in $changes) {
  Set-RegistryValueIfDifferent -Path $change.Path -Name $change.Name -Value $change.Value -PropertyType DWord | Out-Null
}
