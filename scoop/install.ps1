try {
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -ErrorAction Stop
}
catch {
  Write-Warning "Could not set execution policy at CurrentUser scope: $($_.Exception.Message)"
}

$logPath = "$PSScriptRoot/install.log"
Invoke-WebRequest -Uri 'https://get.scoop.sh' | Invoke-Expression *> $logPath

if (-not $?) {
  throw "Scoop bootstrap script failed. Check '$logPath' for details."
}

if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
  throw "Scoop command not found after bootstrap. Check '$logPath' for details."
}

scoop install sudo
