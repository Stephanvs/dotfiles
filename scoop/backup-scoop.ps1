Set-Location $PSScriptRoot
Write-Host "Backing up scoop apps list"

# export apps list
scoop export > apps.json

# commit only apps.json, leaving any other changes in the repo untouched
git add apps.json
git diff --cached --quiet -- apps.json
if ($LASTEXITCODE -eq 0) {
  Write-Host "No changes to apps list"
} else {
  git commit -m "chore: backup of scoop apps" -- apps.json
  Write-Host "Backup completed"
}
