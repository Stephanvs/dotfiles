Import-Module -Name "$PSScriptRoot\..\lib\Symlink.psm1"
Import-Module -Name "$PSScriptRoot\..\lib\Set-WindowsStartupEntry.psm1"

foreach ($link in @(
    @{ Name = 'applications.json'; Label = 'Komorebi applications link' },
    @{ Name = 'komorebi.ahk'; Label = 'Komorebi AHK link' },
    @{ Name = 'komorebi.bar.monitor1.json'; Label = 'Komorebi monitor 1 bar config link' },
    @{ Name = 'komorebi.bar.monitor2.json'; Label = 'Komorebi monitor 2 bar config link' },
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
    Write-Host "Configured Komorebi autostart with bar for $komorebiConfigPath"
}
else {
    Write-Warning 'komorebic was not found; skipping Komorebi autostart configuration.'
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
