. "$PSScriptRoot/_helpers.ps1"

Assert-Administrator

$packageMatchPattern = '*WebExperience*'
$taskbarWidgetsHidden = 0
$taskbarWidgetsShown = 1
$widgetsDisabled = 0
$widgetsEnabled = 1

$packages = @(Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Where-Object { $_.Name -like $packageMatchPattern })
foreach ($package in $packages) {
  try {
    Remove-AppxPackage -Package $package.PackageFullName -AllUsers -ErrorAction Stop
  }
  catch {
    Write-Warning "Failed to remove widget package '$($package.Name)': $($_.Exception.Message)"
  }
}

Set-RegistryValueIfDifferent `
  -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' `
  -Name 'TaskbarDn' `
  -Value $taskbarWidgetsHidden `
  -PropertyType DWord | Out-Null

Set-RegistryValueIfDifferent `
  -Path 'HKLM:\Software\Policies\Microsoft\Dsh' `
  -Name 'AllowNewsAndInterests' `
  -Value $widgetsDisabled `
  -PropertyType DWord | Out-Null
