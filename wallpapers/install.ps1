$CurrentWallpaper = Join-Path $PSScriptRoot "current"
$DefaultWallpaper = "palm_booster.jpeg"

function Initialize-CurrentWallpaper {
    $defaultWallpaperPath = Join-Path $PSScriptRoot $DefaultWallpaper

    if (-not (Test-Path -LiteralPath $defaultWallpaperPath -PathType Leaf))
    {
        Write-Warning "Wallpaper not found: $defaultWallpaperPath"
        exit 1
    }

    if (-not (Get-Item -LiteralPath $CurrentWallpaper -Force -ErrorAction SilentlyContinue))
    {
        Push-Location $PSScriptRoot
        try
        {
            New-Item -ItemType SymbolicLink -Path "current" -Target $DefaultWallpaper -ErrorAction Stop | Out-Null
        }
        catch
        {
            Write-Warning "Failed to create wallpaper symlink: $CurrentWallpaper -> $DefaultWallpaper. Enable Developer Mode or run PowerShell as Administrator."
            exit 1
        }
        finally
        {
            Pop-Location
        }
    }

    $item = Get-Item -LiteralPath $CurrentWallpaper -Force
    if ($item.LinkType -eq "SymbolicLink" -and $item.Target)
    {
        $target = $item.Target
        if (-not [System.IO.Path]::IsPathRooted($target))
        {
            $target = Join-Path $PSScriptRoot $target
        }

        return (Resolve-Path -LiteralPath $target).Path
    }

    return (Resolve-Path -LiteralPath $CurrentWallpaper).Path
}

$Wallpaper = (Initialize-CurrentWallpaper).ToLowerInvariant()

$current = Get-ItemPropertyValue -Path "HKCU:\Control Panel\Desktop" -Name WallPaper
Write-Host "Current Wallpaper: $current"

if ($current -ne $Wallpaper)
{
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
