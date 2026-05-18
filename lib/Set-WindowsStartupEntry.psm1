function Set-WindowsStartupEntry {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Command,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    $runKeyPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
    $startupApprovedRunKeyPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'
    $existingStartupCommand = $null

    if (Test-Path -LiteralPath $runKeyPath) {
        $existingRunEntry = Get-ItemProperty -Path $runKeyPath -Name $Name -ErrorAction SilentlyContinue
        if ($existingRunEntry) {
            $existingStartupCommand = $existingRunEntry.$Name
        }
    }

    if ($existingStartupCommand -eq $Command) {
        Write-Host "$Label already configured"
    }
    else {
        if (-not (Test-Path -LiteralPath $runKeyPath)) {
            New-Item -Path $runKeyPath -Force | Out-Null
        }

        New-ItemProperty -Path $runKeyPath -Name $Name -PropertyType String -Value $Command -Force | Out-Null

        Write-Host "Configured $Label"
    }

    if (Test-Path -LiteralPath $startupApprovedRunKeyPath) {
        $startupApprovedEntry = Get-ItemProperty -Path $startupApprovedRunKeyPath -Name $Name -ErrorAction SilentlyContinue
        if ($startupApprovedEntry) {
            Remove-ItemProperty -Path $startupApprovedRunKeyPath -Name $Name -ErrorAction Stop
            Write-Host "Reset Windows Startup Apps approval for $Label"
        }
    }
}

Export-ModuleMember -Function Set-WindowsStartupEntry
