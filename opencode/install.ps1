Import-Module -Name "$PSScriptRoot\..\lib\Symlink.psm1"

foreach ($link in @(
    @{ Name = 'opencode.json'; Label = 'OpenCode config link' },
    @{ Name = 'tui.json'; Label = 'OpenCode TUI config link' },
    @{ Name = 'prompts'; Label = 'OpenCode prompts link' },
    @{ Name = 'skill'; Label = 'OpenCode skill link' },
    @{ Name = 'rules'; Label = 'OpenCode rules link' },
    @{ Name = 'AGENTS.md'; Label = 'OpenCode agents link' },
    @{ Name = 'command'; Label = 'OpenCode command link' }
)) {
    New-Symlink -SourcePath "$PSScriptRoot/$($link.Name)" -TargetPath "$HOME/.config/opencode/$($link.Name)" -Label $link.Label
}
