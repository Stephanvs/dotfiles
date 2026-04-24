. "$PSScriptRoot/_helpers.ps1"

$path = 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'
Ensure-RegistryKey -Path $path
$registryKey = Get-Item -LiteralPath $path
$changed = $registryKey.GetValue('') -cne ''

if ($changed) {
  $registryKey.SetValue('', '')
}

if ($changed) {
  Write-Host 'Enabled the classic Windows context menu.'
}
