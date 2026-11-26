$failed = @()

Write-Host 'Updating scoop apps' -ForegroundColor Cyan
scoop update *
if ($LASTEXITCODE -ne 0) { $failed += 'scoop' }

Write-Host 'Upgrading winget packages' -ForegroundColor Cyan
winget upgrade --all --accept-source-agreements --accept-package-agreements
if ($LASTEXITCODE -ne 0) { $failed += 'winget' }

if ($failed) {
  Write-Warning "Update finished with errors from: $($failed -join ', ')"
  exit 1
}

Write-Host 'Update completed' -ForegroundColor Green
