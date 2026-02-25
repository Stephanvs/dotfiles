Set-ExecutionPolicy Unrestricted -Scope Process

& ([scriptblock]::Create((irm "https://win11debloat.raphi.re/"))) `
  -DisableDVR `
  -DisableTelemetry `
  -DisableBing `
  -DisableSuggestions `
  -DisableLockscreenTips `
  -RevertContextMenu `
  -ShowHiddenFolders `
  -ShowKnownFileExt `
  -HideDupliDrive `
  -TaskbarAlignLeft `
  -ShowSearchBoxTb `
  -HideChat `
  -DisableWidgets `
  -DisableCopilot `
  -DisableRecall `
  -HideGallery `
  -Silent

Invoke-Command {reg import ./keyboard-rate.reg *>&1 | Out-Null}

& $PSScriptRoot/Taskbar-CombineApps.ps1
& $PSScriptRoot/Remove-DesktopShortcuts.ps1
& $PSScriptRoot/Install-Apps.ps1
& $PSScriptRoot/disable-lock-workstation.ps1
