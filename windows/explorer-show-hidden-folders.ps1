. "$PSScriptRoot/_helpers.ps1"

$showHiddenFiles = 1
$hideHiddenFiles = 2

Set-RegistryValueIfDifferent `
  -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' `
  -Name 'Hidden' `
  -Value $showHiddenFiles `
  -PropertyType DWord | Out-Null
