. "$PSScriptRoot/_helpers.ps1"

$hideGallery = 0
$showGallery = 1

Set-RegistryValueIfDifferent `
  -Path 'HKCU:\Software\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}' `
  -Name 'System.IsPinnedToNameSpaceTree' `
  -Value $hideGallery `
  -PropertyType DWord | Out-Null
