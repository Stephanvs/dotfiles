$EnableLockWorkstation = 0
$DisableLockWorkstation = 1

$Value = $DisableLockWorkstation

$PropertyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System"
$PropertyName = "DisableLockWorkstation"

if (-not (Test-Path -Path $PropertyPath)) {
  New-Item -Path $PropertyPath -Force | Out-Null
}

$CurrentValue = Get-ItemPropertyValue -Path $PropertyPath -Name $PropertyName -ErrorAction SilentlyContinue
Write-Host "Current $PropertyName Property = $CurrentValue"

if ($CurrentValue -ne $Value) {
  Write-Host "Setting $PropertyName to value: $Value"
  New-ItemProperty -Path $PropertyPath -Name $PropertyName -PropertyType DWord -Value $Value -Force | Out-Null
}
