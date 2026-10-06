Set-Location $PSScriptRoot
Write-Host "Backing up scoop apps list"

# export apps list
scoop export > apps.json

# commit only apps.json, leaving any other changes in the repo untouched
git add apps.json
git diff --cached --quiet -- apps.json
if ($LASTEXITCODE -eq 0) {
  Write-Host "No changes to apps list"
  return
}

git commit -m "chore: backup of scoop apps" -- apps.json

# sync with the remote before pushing, in case it moved on since the last pull.
# --autostash only stashes when there are local changes and always restores them.
git pull --rebase --autostash
if ($LASTEXITCODE -ne 0) {
  git rebase --abort 2>$null
  Write-Warning "Could not sync with remote; backup committed locally only"
  return
}

git push
if ($LASTEXITCODE -ne 0) {
  Write-Warning "Push failed; backup committed locally only"
  return
}

Write-Host "Backup completed and pushed"
