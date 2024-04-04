Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-WebRequest -useb get.scoop.sh | Invoke-Expression > install.log

Write-Host $LASTEXITCODE
if ($LASTEXITCODE -eq 0) {
  $path = (Resolve-Path -Path ./install.log)
  Write-Warning "scoop install script extited with code $LASTEXITCODE check '$path' for details"
}

scoop install sudo