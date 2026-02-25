try {
    [Environment]::SetEnvironmentVariable('HOST_IPV4', 'activation.prosim-ar.com', 'Machine')
}
catch {
    Write-Error "Could not set HOST_IPV4 at Machine scope: $($_.Exception.Message)"
}
