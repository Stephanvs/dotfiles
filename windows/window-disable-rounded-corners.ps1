. "$PSScriptRoot/_helpers.ps1"

$roundedCornersEnabled = 1
$roundedCornersDisabled = 0

$changed = Set-RegistryValueIfDifferent `
  -Path 'HKCU:\Software\Microsoft\Windows\DWM' `
  -Name 'UseWindowFrameStagingBuffer' `
  -Value $roundedCornersDisabled `
  -PropertyType DWord

if (-not ('WindowCornerPreference' -as [type])) {
  Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class WindowCornerPreference {
  private const int DwmWaWindowCornerPreference = 33;
  private const int DwmWcpDoNotRound = 1;

  private delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

  [DllImport("user32.dll")]
  private static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

  [DllImport("user32.dll")]
  private static extern bool IsWindow(IntPtr hWnd);

  [DllImport("dwmapi.dll")]
  private static extern int DwmSetWindowAttribute(IntPtr hwnd, int dwAttribute, ref int pvAttribute, int cbAttribute);

  public static void ApplySquareCorners() {
    EnumWindows(delegate (IntPtr hWnd, IntPtr lParam) {
      if (IsWindow(hWnd)) {
        int preference = DwmWcpDoNotRound;
        DwmSetWindowAttribute(hWnd, DwmWaWindowCornerPreference, ref preference, sizeof(int));
      }

      return true;
    }, IntPtr.Zero);
  }
}
'@
}

[WindowCornerPreference]::ApplySquareCorners()

if ($changed) {
  Write-Host 'Disabled rounded window corners.'
}
