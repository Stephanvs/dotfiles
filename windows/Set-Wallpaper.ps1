Set-ItemProperty `
  -Path "HKCU:Control Panel\Desktop" `
  -Name WallPaper `
  -Value (Get-Item ..\wallpapers\nasa.jpg | Resolve-Path).ProviderPath

Start-Sleep -Seconds 5

# Required to reload the PerUser settings
RUNDLL32.EXE USER32.DLL, UpdatePerUserSystemParameters , 1 , True


# Use the line below to verify that the wallpaper has been set
#Get-ItemProperty -path "HKCU:\Control Panel\Desktop"