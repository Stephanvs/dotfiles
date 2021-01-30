# Find all `install.ps1` files recursively
$files = Get-ChildItem -Recurse -Filter install.ps1 -File
foreach ($f in $files) {
  Write-Output "executing: $f"

  # Invoke the install script
  & $f
}