. "$PSScriptRoot/_helpers.ps1"

$hidden = 0
$iconOnly = 1
$fullInputBox = 2

Set-RegistryValueIfDifferent `
    -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' `
    -Name 'SearchboxTaskbarMode' `
    -Value $hidden `
    -PropertyType DWord | Out-Null
