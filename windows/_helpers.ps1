[CmdletBinding()]
param ()

function Test-IsAdministrator {
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = New-Object Security.Principal.WindowsPrincipal($identity)
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-Administrator {
  if (-not (Test-IsAdministrator)) {
    throw "This script requires elevated privileges. Run it from an administrator PowerShell session."
  }
}

function Ensure-RegistryKey {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -Path $Path -Force | Out-Null
  }
}

function Set-RegistryValueIfDifferent {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [Parameter(Mandatory = $true)]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [Object]$Value,

    [Parameter(Mandatory = $true)]
    [ValidateSet('String', 'ExpandString', 'DWord', 'QWord', 'Binary', 'MultiString')]
    [string]$PropertyType
  )

  Ensure-RegistryKey -Path $Path
  $currentValue = Get-ItemPropertyValue -Path $Path -Name $Name -ErrorAction SilentlyContinue

  if ($currentValue -ceq $Value) {
    return $false
  }

  New-ItemProperty -Path $Path -Name $Name -PropertyType $PropertyType -Value $Value -Force | Out-Null
  return $true
}

function Remove-RegistryKeyIfExists {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    return $false
  }

  Remove-Item -LiteralPath $Path -Recurse -Force
  return $true
}

function Remove-RegistryValueIfExists {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [Parameter(Mandatory = $true)]
    [string]$Name
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    return $false
  }

  $item = Get-Item -LiteralPath $Path
  if ($null -eq $item.GetValue($Name, $null, 'DoNotExpandEnvironmentNames')) {
    return $false
  }

  Remove-ItemProperty -Path $Path -Name $Name -Force
  return $true
}

function Remove-AppxPackageIfInstalled {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Name
  )

  $packages = @(Get-AppxPackage -Name $Name -ErrorAction SilentlyContinue)
  if ($packages.Count -eq 0) {
    return $false
  }

  $removed = $false
  foreach ($package in $packages) {
    try {
      Remove-AppxPackage -Package $package.PackageFullName -ErrorAction Stop
      $removed = $true
    }
    catch {
      Write-Warning "Failed to remove AppX package '$Name': $($_.Exception.Message)"
    }
  }

  return $removed
}
