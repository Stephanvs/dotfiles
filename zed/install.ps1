Import-Module -Name "$PSScriptRoot\..\lib\Symlink.psm1"

function New-ZedConfigLink {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [Parameter(Mandatory = $true)]
        [string]$TargetPath,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    try {
        New-Symlink -SourcePath $SourcePath -TargetPath $TargetPath -Label $Label
        return
    }
    catch {
        if ($_.Exception.Message -notmatch 'Administrator|Developer Mode') {
            throw
        }
    }

    New-Item -ItemType Directory -Path (Split-Path -Path $TargetPath -Parent) -Force -ErrorAction Stop | Out-Null

    if (Test-Path -LiteralPath $TargetPath) {
        Remove-Item -LiteralPath $TargetPath -Force -ErrorAction Stop
    }

    New-Item -ItemType HardLink -Path $TargetPath -Target $SourcePath -Force -ErrorAction Stop | Out-Null
    Write-Host "$Label hard-linked $TargetPath -> $SourcePath"
}

New-ZedConfigLink -SourcePath "$PSScriptRoot/settings.json" -TargetPath "$env:APPDATA/Zed/settings.json" -Label 'Zed settings link'
New-ZedConfigLink -SourcePath "$PSScriptRoot/keymap.json" -TargetPath "$env:APPDATA/Zed/keymap.json" -Label 'Zed keymap link'
