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
}

Export-ModuleMember -Function Set-WindowsStartupEntry
