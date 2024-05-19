# This script needs admin rights to run

# First remove the installed package for each user
Get-AppxPackage -AllUsers `
    | Where-Object {$_.Name -like "*WebExperience*"} `
    | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue

$Path  = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$Key_Widgets = "TaskbarDn"
$KeyFormat = "DWord"
$Value = "0"

if (!(Test-Path $Path)) { New-Item -Path $Path -Force }
Set-ItemProperty -Path $Path -Name $Key_Widgets -Value $Value -Type $KeyFormat

$Path = "HKLM:\Software\Policies\Microsoft\Dsh"
$Key = "AllowNewsAndInterests"
$KeyFormat = "DWord"
$Value = "0"

if (!(Test-Path -Path $Path)) { New-Item -Path $Path -Force }
Set-ItemProperty -Path $Path -Name $Key -Value $Value -Type $KeyFormat
