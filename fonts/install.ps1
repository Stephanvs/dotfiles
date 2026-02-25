$ErrorActionPreference = 'Stop'

Write-Host 'Installing fonts'

$fontsFolder = (New-Object -ComObject Shell.Application).Namespace(0x14)
if (-not $fontsFolder) {
  throw 'Unable to open Windows Fonts shell folder.'
}

$registryPaths = @(
  'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts',
  'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
)

$fontDirectories = @(
  (Join-Path $env:WINDIR 'Fonts'),
  (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts')
)

$fontExtensions = @('.ttf', '.otf')

$installedFontFiles = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

foreach ($registryPath in $registryPaths) {
  if (-not (Test-Path -Path $registryPath)) {
    continue
  }

  $properties = (Get-ItemProperty -Path $registryPath).PSObject.Properties |
    Where-Object { $_.Name -notmatch '^PS(Path|ParentPath|ChildName|Drive|Provider)$' }

  foreach ($property in $properties) {
    if ([string]::IsNullOrWhiteSpace([string]$property.Value)) {
      continue
    }

    $fontFileName = [System.IO.Path]::GetFileName([string]$property.Value)
    if (-not [string]::IsNullOrWhiteSpace($fontFileName)) {
      [void]$installedFontFiles.Add($fontFileName)
    }
  }
}

foreach ($fontDirectory in $fontDirectories) {
  if (-not (Test-Path -LiteralPath $fontDirectory)) {
    continue
  }

  Get-ChildItem -LiteralPath $fontDirectory -File |
    Where-Object { $fontExtensions -contains $_.Extension } |
    ForEach-Object { [void]$installedFontFiles.Add($_.Name) }
}

$fontFiles = Get-ChildItem -Path $PSScriptRoot -Recurse -File |
  Where-Object { $fontExtensions -contains $_.Extension } |
  Sort-Object FullName |
  Group-Object -Property Name |
  ForEach-Object { $_.Group[0] }

foreach ($fontFile in $fontFiles) {
  if ($installedFontFiles.Contains($fontFile.Name)) {
    Write-Verbose "Already installed: $($fontFile.Name)"
    continue
  }

  # FOF_SILENT (0x4) + FOF_NOCONFIRMATION (0x10)
  $fontsFolder.CopyHere($fontFile.FullName, 0x14)
  [void]$installedFontFiles.Add($fontFile.Name)
  Write-Host "Installed: $($fontFile.Name)"
}
