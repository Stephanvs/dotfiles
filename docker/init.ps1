[CmdletBinding()]
Param(
)

function Invoke-DockerCompose-Up { & docker-compose up -d }
# function Set-GitCommit { & git commit -m $args }

Write-Verbose "Setting Docker aliases:"

Set-Alias -Name dcu -Value Invoke-DockerCOmpose-Up -Force -Scope Global

Write-Verbose "Docker aliases installed."