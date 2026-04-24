. "$PSScriptRoot/_helpers.ps1"

$enabled = 0
$disabled = 1

Set-RegistryValueIfDifferent `
  -Path 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' `
  -Name 'DisableSearchBoxSuggestions' `
  -Value $disabled `
  -PropertyType DWord | Out-Null

Remove-AppxPackageIfInstalled -Name 'Microsoft.BingSearch' | Out-Null
