$desktopPath = Join-Path $HOME 'Desktop'
$shortcuts = @(Get-ChildItem -Path $desktopPath -Filter '*.lnk' -File -ErrorAction SilentlyContinue)

if ($shortcuts.Count -eq 0) {
  return
}

Remove-Item -LiteralPath $shortcuts.FullName -Force -ErrorAction SilentlyContinue
