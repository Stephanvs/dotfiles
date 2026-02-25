Import-Module -Name "$PSScriptRoot\..\lib\Symlink.psm1"

foreach ($link in @(
    @{ Name = 'applications.json'; Label = 'Komorebi applications link' },
    @{ Name = 'komorebi.ahk'; Label = 'Komorebi AHK link' },
    @{ Name = 'komorebi.json'; Label = 'Komorebi config link' }
)) {
    New-Symlink -SourcePath "$PSScriptRoot/$($link.Name)" -TargetPath "$HOME/$($link.Name)" -Label $link.Label
}
