Import-Module -Name "$PSScriptRoot\..\lib\Symlink.psm1"
Import-Module -Name "$PSScriptRoot\..\lib\Set-WindowsStartupEntry.psm1"

foreach ($link in @(
    @{ Name = 'applications.json'; Label = 'Komorebi applications link' },
    @{ Name = 'komorebi.ahk'; Label = 'Komorebi AHK link' },
    @{ Name = 'komorebi.bar.json'; Label = 'Komorebi bar config link' },
    @{ Name = 'komorebi.json'; Label = 'Komorebi config link' }
)) {
    New-Symlink -SourcePath "$PSScriptRoot/$($link.Name)" -TargetPath "$HOME/$($link.Name)" -Label $link.Label
}

$komorebicCommand = Get-Command komorebic.exe -ErrorAction SilentlyContinue

if (-not $komorebicCommand) {
    $komorebicCommand = Get-Command komorebic -ErrorAction SilentlyContinue
}

if ($komorebicCommand) {
    $komorebiConfigPath = Join-Path -Path $HOME -ChildPath 'komorebi.json'
    & $komorebicCommand.Source enable-autostart --config $komorebiConfigPath --bar

    if ($LASTEXITCODE -ne 0) {
        throw 'Failed to configure Komorebi autostart.'
    }

    $startupApprovedFolderKeyPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder'

    if (Test-Path -LiteralPath $startupApprovedFolderKeyPath) {
        $approvedStartupFolderEntry = Get-ItemProperty -Path $startupApprovedFolderKeyPath -Name 'komorebi.lnk' -ErrorAction SilentlyContinue
        if ($approvedStartupFolderEntry) {
            Remove-ItemProperty -Path $startupApprovedFolderKeyPath -Name 'komorebi.lnk' -ErrorAction Stop
            Write-Host 'Reset Windows Startup Apps approval for komorebi.lnk'
        }
    }

    Write-Host "Configured Komorebi autostart with bar for $komorebiConfigPath"
}
else {
    Write-Warning 'komorebic was not found; skipping Komorebi autostart configuration.'
}

$legacyKomorebiBarRunKeyPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$legacyKomorebiBarStartupApprovedKeyPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'

if (Test-Path -LiteralPath $legacyKomorebiBarRunKeyPath) {
    $legacyKomorebiBarRunEntry = Get-ItemProperty -Path $legacyKomorebiBarRunKeyPath -Name 'KomorebiBar' -ErrorAction SilentlyContinue
    if ($legacyKomorebiBarRunEntry) {
        Remove-ItemProperty -Path $legacyKomorebiBarRunKeyPath -Name 'KomorebiBar' -ErrorAction Stop
        Write-Host 'Removed legacy KomorebiBar registry startup entry'
    }
}

if (Test-Path -LiteralPath $legacyKomorebiBarStartupApprovedKeyPath) {
    $legacyKomorebiBarApprovalEntry = Get-ItemProperty -Path $legacyKomorebiBarStartupApprovedKeyPath -Name 'KomorebiBar' -ErrorAction SilentlyContinue
    if ($legacyKomorebiBarApprovalEntry) {
        Remove-ItemProperty -Path $legacyKomorebiBarStartupApprovedKeyPath -Name 'KomorebiBar' -ErrorAction Stop
        Write-Host 'Removed legacy KomorebiBar Startup Apps approval entry'
    }
}

$autohotkeyCommand = Get-Command autohotkey.exe -ErrorAction SilentlyContinue

if (-not $autohotkeyCommand) {
    $autohotkeyCommand = Get-Command autohotkey -ErrorAction SilentlyContinue
}

$autohotkeyPath = if ($autohotkeyCommand) { $autohotkeyCommand.Source } else { 'autohotkey.exe' }
$komorebiAhkPath = Join-Path -Path $HOME -ChildPath 'komorebi.ahk'
$startupCommand = '"{0}" "{1}"' -f $autohotkeyPath, $komorebiAhkPath

Set-WindowsStartupEntry `
    -Name 'KomorebiAutoHotkey' `
    -Command $startupCommand `
    -Label "Windows startup entry for $komorebiAhkPath"
