. "$PSScriptRoot/_helpers.ps1"

$propertyPath = 'HKCU:\Control Panel\Accessibility\Keyboard Response'

$autoRepeatDelayFast = '200'
$autoRepeatDelayDefault = '500'
$autoRepeatRateFast = '200'
$autoRepeatRateDefault = '500'
$bounceTimeDisabled = '0'
$delayBeforeAcceptanceShort = '500'
$delayBeforeAcceptanceDefault = '1000'
$flagsEnabled = '114'

$lastBounceKeySettingDisabled = 0
$lastBounceKeySettingEnabled = 1
$lastValidDelayDisabled = 0
$lastValidRepeatDisabled = 0
$lastValidWaitDefault = 1000

$stringProperties = @{
  AutoRepeatDelay = $autoRepeatDelayFast
  AutoRepeatRate = $autoRepeatRateFast
  BounceTime = $bounceTimeDisabled
  DelayBeforeAcceptance = $delayBeforeAcceptanceShort
  Flags = $flagsEnabled
}

$dwordProperties = @{
  'Last BounceKey Setting' = $lastBounceKeySettingDisabled
  'Last Valid Delay' = $lastValidDelayDisabled
  'Last Valid Repeat' = $lastValidRepeatDisabled
  'Last Valid Wait' = $lastValidWaitDefault
}

Ensure-RegistryKey -Path $propertyPath

foreach ($property in $stringProperties.GetEnumerator()) {
  Set-RegistryValueIfDifferent -Path $propertyPath -Name $property.Key -Value $property.Value -PropertyType String | Out-Null
}

foreach ($property in $dwordProperties.GetEnumerator()) {
  Set-RegistryValueIfDifferent -Path $propertyPath -Name $property.Key -Value $property.Value -PropertyType DWord | Out-Null
}
