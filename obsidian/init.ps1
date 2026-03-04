[CmdletBinding()]
Param(
)

function Invoke-Obsidian {
  [CmdletBinding()]
  Param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
  )

  if (-not $Arguments -or $Arguments.Count -eq 0) {
    Start-Process -FilePath "obsidian" | Out-Null
    $global:LASTEXITCODE = 0
    return
  }

  $stdoutPath = [System.IO.Path]::GetTempFileName()
  $stderrPath = [System.IO.Path]::GetTempFileName()

  try {
    $process = Start-Process -FilePath "obsidian" -ArgumentList $Arguments -PassThru -NoNewWindow -Wait -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath

    if ((Get-Item -LiteralPath $stdoutPath).Length -gt 0) {
      Get-Content -LiteralPath $stdoutPath
    }

    if ((Get-Item -LiteralPath $stderrPath).Length -gt 0) {
      Get-Content -LiteralPath $stderrPath | ForEach-Object { [Console]::Error.WriteLine($_) }
    }

    $global:LASTEXITCODE = $process.ExitCode
  }
  finally {
    Remove-Item -LiteralPath $stdoutPath, $stderrPath -ErrorAction SilentlyContinue
  }
}

Set-Alias -Name obsidian -Value Invoke-Obsidian -Force -Scope Global
