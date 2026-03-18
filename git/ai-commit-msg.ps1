[CmdletBinding()]
Param()

function Invoke-OpencodePrompt {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Executable,

    [Parameter(Mandatory = $true)]
    [string]$Model,

    [Parameter(Mandatory = $true)]
    [string]$Prompt,

    [string[]]$Files = @()
  )

  $psi = [System.Diagnostics.ProcessStartInfo]::new()
  $psi.FileName = $Executable
  $psi.UseShellExecute = $false
  $psi.CreateNoWindow = $true
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
  $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8
  $null = $psi.ArgumentList.Add("run")
  $null = $psi.ArgumentList.Add("--format")
  $null = $psi.ArgumentList.Add("json")
  $null = $psi.ArgumentList.Add("-m")
  $null = $psi.ArgumentList.Add($Model)
  foreach ($file in $Files) {
    $null = $psi.ArgumentList.Add("-f")
    $null = $psi.ArgumentList.Add($file)
  }
  $null = $psi.ArgumentList.Add("--")
  $null = $psi.ArgumentList.Add($Prompt)

  $process = [System.Diagnostics.Process]::new()
  $process.StartInfo = $psi

  try {
    $null = $process.Start()
  }
  catch {
    return [PSCustomObject]@{
      ExitCode = 1
      Text = $null
      Error = $_.Exception.Message
    }
  }

  $stdout = $process.StandardOutput.ReadToEnd()
  $stderr = $process.StandardError.ReadToEnd()
  $process.WaitForExit()

  $text = $null
  foreach ($line in $stdout -split "`r?`n") {
    if (-not $line.StartsWith("{")) {
      continue
    }

    try {
      $event = $line | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
      continue
    }

    if ($event.type -eq "text" -and -not [string]::IsNullOrWhiteSpace($event.part.text)) {
      $text = $event.part.text
    }
  }

  return [PSCustomObject]@{
    ExitCode = $process.ExitCode
    Text = $text
    Error = $stderr.Trim()
  }
}

$diff = (& git diff --cached | Out-String).TrimEnd()
if ([string]::IsNullOrWhiteSpace($diff)) {
  Write-Host "No staged changes found."
  return
}

if (-not ($opencode = Get-Command opencode -ErrorAction SilentlyContinue)) {
  Write-Host "Error: opencode is not installed or not in PATH"
  return
}

$model = "openai/gpt-5.3-codex-spark"
$tempDiff = Join-Path ([System.IO.Path]::GetTempPath()) ("gcmai-" + [System.Guid]::NewGuid().ToString("N") + ".diff")

Set-Content -LiteralPath $tempDiff -Value $diff -Encoding utf8

$prompt = @"
Generate a conventional commit message for the attached staged diff. Output ONLY the commit message - no explanations, no markdown, no code blocks, no quotes around the message.
"@

$result = $null
try {
  $result = Invoke-OpencodePrompt -Executable $opencode.Source -Model $model -Prompt $prompt -Files @($tempDiff)
}
finally {
  Remove-Item -LiteralPath $tempDiff -Force -ErrorAction SilentlyContinue
}

$msg = $result.Text

if ([string]::IsNullOrWhiteSpace($msg)) {
  if (-not [string]::IsNullOrWhiteSpace($result.Error)) {
    $errorLine = $result.Error -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Last 1
    if (-not [string]::IsNullOrWhiteSpace($errorLine)) {
      Write-Host "Error: $errorLine"
      return
    }
  }

  Write-Host "Error: Failed to generate commit message"
  return
}

$msg = $msg.Trim()

try {
  Set-Clipboard -Value $msg
}
catch {
  Write-Host "Warning: Failed to copy message to clipboard"
}

Write-Host $msg
Write-Host ""
Write-Host "---"
Write-Host "Copied to clipboard! Press c, then <c-o> p to paste."
