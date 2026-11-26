Set-Alias pbcopy Set-Clipboard
Set-Alias pbpaste Get-Clipboard
Set-Alias pb-copy Set-Clipboard
Set-Alias pb-paste Get-Clipboard

function Get-AllItems { & eza --icons --group-directories-first --sort size --all --no-filesize --no-permissions --no-time --no-quotes }

Set-Alias -Name l -Value Get-AllItems -Force -Scope Global
Remove-Alias -Name where -Force -Scope Global
function where { Get-Command @args }
Set-Alias -Name which -Value Get-Command -Force -Scope Global

# Same moniker as `bubu` on macOS: update scoop and winget packages, elevated.
# When not elevated, the script runs in a hidden elevated pwsh that writes all
# output to a log, and that log is streamed into this shell as it grows. The
# output stays in this window's scrollback after the update finishes.
function Update-AllPackages {
  $script = "$PSScriptRoot\update-all.ps1"
  $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).
    IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

  if ($isAdmin) {
    & $script
    return
  }

  $log = Join-Path ([IO.Path]::GetTempPath()) "bubu-$([guid]::NewGuid()).log"
  New-Item -ItemType File -Path $log | Out-Null
  $command = "& '$script' *> '$log'; exit `$LASTEXITCODE"

  try {
    $proc = Start-Process pwsh -Verb RunAs -WindowStyle Hidden -PassThru `
      -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', $command
  }
  catch {
    Remove-Item $log -ErrorAction SilentlyContinue
    Write-Warning 'Elevation was cancelled'
    return
  }

  $stream = [IO.FileStream]::new($log, 'Open', 'Read', 'ReadWrite, Delete')
  $reader = [IO.StreamReader]::new($stream, [Text.Encoding]::UTF8)
  try {
    while (-not $proc.HasExited) {
      [Console]::Out.Write($reader.ReadToEnd())
      Start-Sleep -Milliseconds 200
    }
    [Console]::Out.Write($reader.ReadToEnd())
  }
  finally {
    $reader.Dispose()
    Remove-Item $log -ErrorAction SilentlyContinue
  }

  if ($proc.ExitCode -ne 0) {
    Write-Warning "Update exited with code $($proc.ExitCode)"
  }
}
Set-Alias -Name bubu -Value Update-AllPackages -Force -Scope Global
