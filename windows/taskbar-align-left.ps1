. "$PSScriptRoot/_helpers.ps1"

$leftAligned = 0
$centerAligned = 1

$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$name = "TaskbarAl"
$value = $leftAligned

$changed = Set-RegistryValueIfDifferent -Path $registryPath -Name $name -Value $value -PropertyType DWord
if ($changed) {
  Write-Host "Aligned taskbar buttons to the left."
}

