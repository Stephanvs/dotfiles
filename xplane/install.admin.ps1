. "$PSScriptRoot/../windows/_helpers.ps1"

Assert-Administrator

$XPlaneHome = 'E:\SteamLibrary\steamapps\common\X-Plane 12'
$currentMachineValue = [Environment]::GetEnvironmentVariable('XPLANE_HOME', 'Machine')

if ($currentMachineValue -eq $XPlaneHome) {
  return
}

[Environment]::SetEnvironmentVariable('XPLANE_HOME', $XPlaneHome, 'Machine')
