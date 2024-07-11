$Wallpaper = Resolve-Path "$PSScriptRoot/desert.jpg".ToLower()

$current = Get-ItemPropertyValue -Path "HKCU:\Control Panel\Desktop" -Name WallPaper
Write-Host "Current Wallpaper: $current"

if ($current -ne $Wallpaper) {
  Write-Host "Setting wallpaper to $Wallpaper"

  $setwallpapersrc = @"
    using System.Runtime.InteropServices;

    public class Wallpaper
    {
      public const int SetDesktopWallpaper = 20;
      public const int UpdateIniFile = 0x01;
      public const int SendWinIniChange = 0x02;
      [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
      private static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
      public static void SetWallpaper(string path)
      {
        SystemParametersInfo(SetDesktopWallpaper, 0, path, UpdateIniFile | SendWinIniChange);
      }
    }
"@

  Add-Type -TypeDefinition $setwallpapersrc

  [Wallpaper]::SetWallpaper($Wallpaper)

  # No longer needed to reload the PerUser settings
  # rundll32.exe user32.dll, UpdatePerUserSystemParameters
}
