Write-Host "Backing up scoop apps list"

# create restore point
$date = Get-Date -Format "yyyyMMddHHmmss"
git add --all
git stash save --message "$date"

# export apps list
scoop export > apps.json

# commit to git
git add apps.json
git commit -m "chore: backup of scoop apps"

# restore
git stash apply stash@{0}

Write-Host "Backup completed"