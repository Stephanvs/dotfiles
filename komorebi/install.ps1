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
    & $komorebicCommand.Source enable-autostart --config $komorebiConfigPath

    if ($LASTEXITCODE -ne 0) {
        throw 'Failed to configure Komorebi autostart.'
    }

    Write-Host "Configured Komorebi autostart for $komorebiConfigPath"
}
else {
    Write-Warning 'komorebic was not found; skipping Komorebi autostart configuration.'
}

$komorebiBarCommand = Get-Command komorebi-bar.exe -ErrorAction SilentlyContinue

if (-not $komorebiBarCommand) {
    $komorebiBarCommand = Get-Command komorebi-bar -ErrorAction SilentlyContinue
}

$komorebiBarPath = if ($komorebiBarCommand) { $komorebiBarCommand.Source } else { 'komorebi-bar.exe' }
$komorebiBarConfigPath = Join-Path -Path $HOME -ChildPath 'komorebi.bar.json'
$hiddenLauncherPath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath 'windows\run-hidden.vbs'
$komorebiBarStartupCommand = 'wscript.exe //B //Nologo "{0}" --cwd "{1}" "{2}" --config "{3}"' -f $hiddenLauncherPath, $HOME, $komorebiBarPath, $komorebiBarConfigPath

Set-WindowsStartupEntry `
    -Name 'KomorebiBar' `
    -Command $komorebiBarStartupCommand `
    -Label "Windows startup entry for $komorebiBarConfigPath"

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
