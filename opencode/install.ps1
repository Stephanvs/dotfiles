Import-Module -Name "$PSScriptRoot\..\lib\Symlink.psm1"

foreach ($link in @(
    @{ Name = 'opencode.json'; Label = 'OpenCode config link' },
    @{ Name = 'cli.json'; Label = 'OpenCode CLI config link' },
    @{ Name = 'prompts'; Label = 'OpenCode prompts link' },
    @{ Name = 'skills'; Label = 'OpenCode skills link' },
    @{ Name = 'themes'; Label = 'OpenCode themes link' },
    @{ Name = 'rules'; Label = 'OpenCode rules link' },
    @{ Name = 'AGENTS.md'; Label = 'OpenCode agents link' },
    @{ Name = 'commands'; Label = 'OpenCode commands link' }
)) {
    New-Symlink -SourcePath "$PSScriptRoot/$($link.Name)" -TargetPath "$HOME/.config/opencode/$($link.Name)" -Label $link.Label
}
