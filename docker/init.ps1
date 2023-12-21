[CmdletBinding()]
Param(
)

function Invoke-DockerCompose-Up { & docker-compose up -d }

Write-Verbose "Setting Docker aliases:"
Set-Alias -Name dcu -Value Invoke-DockerCompose-Up -Force -Scope Global
Write-Verbose "Docker aliases installed."

function Switch-Docker($target) {
  if ($target -eq "linux") {
    Write-Host "Switching to Linux Docker engine..."
    & "$env:ProgramFiles\Docker\Docker\DockerCli.exe" -SwitchLinuxEngine
    Write-Host "Switched to Linux Docker engine."
  } else {
    Write-Host "Switching to Windows Docker engine..."
    & "$env:ProgramFiles\Docker\Docker\DockerCli.exe" -SwitchWindowsEngine
    Write-Host "Switched to Windows Docker engine."
  }
}

function Docker-Windows { Switch-Docker "windows" }
function Docker-Linux { Switch-Docker "linux" }
function Docker-Engine { & docker info --format '{{ .OSType }}' }

Set-Alias -Name dockerwin -Value Docker-Windows -Force -Scope Global
Set-Alias -Name dockerlin -Value Docker-Linux -Force -Scope Global
Set-Alias -Name dockerengine -Value Docker-Engine -Force -Scope Global