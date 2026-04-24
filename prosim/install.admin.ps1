$hostIpv4VariableName = 'HOST_IPV4'
$hostIpv4Value = 'activation.prosim-ar.com'
$machineScope = 'Machine'

try {
  [Environment]::SetEnvironmentVariable($hostIpv4VariableName, $hostIpv4Value, $machineScope)
}
catch {
  Write-Error "Could not set $hostIpv4VariableName at $machineScope scope: $($_.Exception.Message)"
}
