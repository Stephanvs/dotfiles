. "$PSScriptRoot/_helpers.ps1"

$alwaysCombine = 0
$combineWhenFull = 1
$neverCombine = 2

$value = $neverCombine
$propertyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$propertyName = "TaskbarGlomLevel"

$changed = Set-RegistryValueIfDifferent -Path $propertyPath -Name $propertyName -Value $value -PropertyType DWord
if ($changed)
{
    Write-Host "Set taskbar combine mode to 'never combine'."
}
