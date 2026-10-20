Import-Module -Name "$PSScriptRoot\..\lib\Symlink.psm1"

$claudeAcpPath = Join-Path $PSScriptRoot 'claude-acp'
$npm = (Get-Command npm.cmd -ErrorAction Stop).Source
& $npm --prefix $claudeAcpPath ci --ignore-scripts --no-audit --no-fund
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to install the Claude ACP plugin dependencies.'
}
& $npm --prefix $claudeAcpPath run build
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to build the Claude ACP plugin.'
}

foreach ($link in @(
    @{ Name = 'opencode.json'; Label = 'OpenCode config link' },
    @{ Name = 'cli.json'; Label = 'OpenCode CLI config link' },
    @{ Name = 'prompts'; Label = 'OpenCode prompts link' },
    @{ Name = 'themes'; Label = 'OpenCode themes link' },
    @{ Name = 'rules'; Label = 'OpenCode rules link' },
    @{ Name = 'AGENTS.md'; Label = 'OpenCode agents link' },
    @{ Name = 'commands'; Label = 'OpenCode commands link' }
)) {
    New-Symlink -SourcePath "$PSScriptRoot/$($link.Name)" -TargetPath "$HOME/.config/opencode/$($link.Name)" -Label $link.Label
}

$claudeAcpLink = Join-Path $HOME '.config/opencode/claude-acp'
if (-not (Test-Path -LiteralPath $claudeAcpLink)) {
    New-Item -ItemType Junction -Path $claudeAcpLink -Target $claudeAcpPath -ErrorAction Stop | Out-Null
}
else {
    New-Symlink -SourcePath $claudeAcpPath -TargetPath $claudeAcpLink -Label 'Claude ACP plugin link'
}
