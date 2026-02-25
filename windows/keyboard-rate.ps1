$PropertyPath = "HKCU:\Control Panel\Accessibility\Keyboard Response"

$StringProperties = @{
  AutoRepeatDelay = "200"
  AutoRepeatRate = "200"
  BounceTime = "0"
  DelayBeforeAcceptance = "500"
  Flags = "114"
}

$DwordProperties = @{
  "Last BounceKey Setting" = 0
  "Last Valid Delay" = 0
  "Last Valid Repeat" = 0
  "Last Valid Wait" = 1000
}

if (-not (Test-Path -Path $PropertyPath)) {
  New-Item -Path $PropertyPath -Force | Out-Null
}

foreach ($Property in $StringProperties.GetEnumerator()) {
  $CurrentValue = Get-ItemPropertyValue -Path $PropertyPath -Name $Property.Key -ErrorAction SilentlyContinue
  Write-Host "Current $($Property.Key) Property = $CurrentValue"

  if ($CurrentValue -ne $Property.Value) {
    Write-Host "Setting $($Property.Key) to value: $($Property.Value)"
    New-ItemProperty -Path $PropertyPath -Name $Property.Key -PropertyType String -Value $Property.Value -Force | Out-Null
  }
}

foreach ($Property in $DwordProperties.GetEnumerator()) {
  $CurrentValue = Get-ItemPropertyValue -Path $PropertyPath -Name $Property.Key -ErrorAction SilentlyContinue
  Write-Host "Current $($Property.Key) Property = $CurrentValue"

  if ($CurrentValue -ne $Property.Value) {
    Write-Host "Setting $($Property.Key) to value: $($Property.Value)"
    New-ItemProperty -Path $PropertyPath -Name $Property.Key -PropertyType DWord -Value $Property.Value -Force | Out-Null
  }
}
