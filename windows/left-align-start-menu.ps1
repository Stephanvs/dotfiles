# Move the Start menu and taskbar to the left
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$name = "TaskbarAl"
$value = 0
New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force

