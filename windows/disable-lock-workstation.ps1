. "$PSScriptRoot/_helpers.ps1"

$lockWorkstationEnabled = 0
$lockWorkstationDisabled = 1

$propertyPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System'
$propertyName = 'DisableLockWorkstation'
$value = $lockWorkstationDisabled

$changed = Set-RegistryValueIfDifferent -Path $propertyPath -Name $propertyName -Value $value -PropertyType DWord
if ($changed) {
  Write-Host 'Disabled locking the workstation from the current user session.'
}
