. "$PSScriptRoot/_helpers.ps1"

Assert-Administrator

Remove-RegistryKeyIfExists -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\DelegateFolders\{F5FB2C77-0E2F-4A16-A381-3E560C68BC83}' | Out-Null
