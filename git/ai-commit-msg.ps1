[CmdletBinding()]
Param()

$diff = (& git diff --cached | Out-String).TrimEnd()
if ([string]::IsNullOrWhiteSpace($diff)) {
  Write-Host "No staged changes found."
  return
}

if (-not (Get-Command opencode -ErrorAction SilentlyContinue)) {
  Write-Host "Error: opencode is not installed or not in PATH"
  return
}

$prompt = @"
Generate a conventional commit message for these staged changes. Output ONLY the commit message - no explanations, no markdown, no code blocks, no quotes around the message:

$diff
"@

$output = & opencode run -m opencode/gpt-5-nano $prompt 2>$null
$msg = $output | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Last 1

if ([string]::IsNullOrWhiteSpace($msg)) {
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
