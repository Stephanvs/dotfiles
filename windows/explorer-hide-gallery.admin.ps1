. "$PSScriptRoot/_helpers.ps1"

Assert-Administrator

$path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\NavPane\ShowGallery'

$checkedValue = 1
$uncheckedValue = 0
$currentUserHive = 2147483649
$galleryOptionId = 13
$galleryOptionText = 'Show Gallery'
$checkboxType = 'checkbox'
$galleryRegistryPath = 'Software\\Classes\\CLSID\\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}'
$galleryValueName = 'System.IsPinnedToNameSpaceTree'

$changes = @(
  @{ Name = 'CheckedValue'; Value = $checkedValue; Type = 'DWord' },
  @{ Name = 'DefaultValue'; Value = $uncheckedValue; Type = 'DWord' },
  @{ Name = 'HKeyRoot'; Value = $currentUserHive; Type = 'DWord' },
  @{ Name = 'Id'; Value = $galleryOptionId; Type = 'DWord' },
  @{ Name = 'RegPath'; Value = $galleryRegistryPath; Type = 'String' },
  @{ Name = 'Text'; Value = $galleryOptionText; Type = 'String' },
  @{ Name = 'Type'; Value = $checkboxType; Type = 'String' },
  @{ Name = 'UncheckedValue'; Value = $uncheckedValue; Type = 'DWord' },
  @{ Name = 'ValueName'; Value = $galleryValueName; Type = 'String' }
)

foreach ($change in $changes) {
  Set-RegistryValueIfDifferent -Path $path -Name $change.Name -Value $change.Value -PropertyType $change.Type | Out-Null
}
