. "$PSScriptRoot/_helpers.ps1"

$widgetsPackageName = 'Microsoft.StartExperiencesApp'

Remove-AppxPackageIfInstalled -Name $widgetsPackageName | Out-Null
