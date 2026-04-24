. "$PSScriptRoot/_helpers.ps1"

$showFileExtensions = 0
$hideFileExtensions = 1

Set-RegistryValueIfDifferent `
  -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' `
  -Name 'HideFileExt' `
  -Value $showFileExtensions `
  -PropertyType DWord | Out-Null
