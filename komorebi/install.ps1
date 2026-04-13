Import-Module -Name "$PSScriptRoot\..\lib\Symlink.psm1"

foreach ($link in @(
    @{ Name = 'applications.json'; Label = 'Komorebi applications link' },
    @{ Name = 'komorebi.ahk'; Label = 'Komorebi AHK link' },
    @{ Name = 'komorebi.json'; Label = 'Komorebi config link' }
)) {
    New-Symlink -SourcePath "$PSScriptRoot/$($link.Name)" -TargetPath "$HOME/$($link.Name)" -Label $link.Label
}

$autohotkeyCommand = Get-Command autohotkey.exe -ErrorAction SilentlyContinue

if (-not $autohotkeyCommand) {
    $autohotkeyCommand = Get-Command autohotkey -ErrorAction SilentlyContinue
}

$autohotkeyPath = if ($autohotkeyCommand) { $autohotkeyCommand.Source } else { 'autohotkey.exe' }
$komorebiAhkPath = Join-Path -Path $HOME -ChildPath 'komorebi.ahk'
$startupCommand = '"{0}" "{1}"' -f $autohotkeyPath, $komorebiAhkPath
$runKeyPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$runValueName = 'KomorebiAutoHotkey'

$existingStartupCommand = $null

if (Test-Path -LiteralPath $runKeyPath) {
    $existingRunEntry = Get-ItemProperty -Path $runKeyPath -Name $runValueName -ErrorAction SilentlyContinue
    if ($existingRunEntry) {
        $existingStartupCommand = $existingRunEntry.$runValueName
    }
}

if ($existingStartupCommand -eq $startupCommand) {
    Write-Host "Windows startup entry already configured for $komorebiAhkPath"
    return
}

New-Item -Path $runKeyPath -Force | Out-Null
New-ItemProperty -Path $runKeyPath -Name $runValueName -PropertyType String -Value $startupCommand -Force | Out-Null

Write-Host "Configured Windows startup entry for $komorebiAhkPath"
