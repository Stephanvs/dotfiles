$AlwaysCombine = 0
$CombineWhenFull = 1
$NeverCombine = 2

$Value = $NeverCombine

$PropertyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

$CurrentValue = Get-ItemPropertyValue -Path $PropertyPath -Name TaskbarGlomLevel
Write-Host "Current Taskbar ItemsCombine Property = $CurrentValue"

if ($CurrentValue -ne $Value) {
  Write-Host "Setting Combine Taskbar buttons to value: $Value"
  Set-ItemProperty -Path $PropertyPath -Name TaskbarGlomLevel -Value $Value
  Stop-Process -Name "Explorer"
}