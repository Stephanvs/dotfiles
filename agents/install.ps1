Import-Module -Name "$PSScriptRoot\..\lib\Symlink.psm1"

# Canonical skill files live in this module. Each harness only sees them if they
# appear in a directory that harness already scans. ~/.agents/skills is the
# shared user store (Codex, OpenCode, Grok). Claude/Cursor/Gemini do not read
# that path, so they get per-skill links of their own.
$skillRoots = @(
    "$HOME/.agents/skills",
    "$HOME/.claude/skills",
    "$HOME/.cursor/skills",
    "$HOME/.gemini/skills"
)

Get-ChildItem -LiteralPath "$PSScriptRoot/skills" -Directory | ForEach-Object {
    foreach ($root in $skillRoots) {
        New-Symlink `
            -SourcePath $_.FullName `
            -TargetPath (Join-Path $root $_.Name) `
            -Label "Skill $($_.Name)"
    }
}

# Tech rules stay authored next to OpenCode's AGENTS.md (which references
# @rules/...). Grok and Claude load home-level rules directories.
Get-ChildItem -LiteralPath "$PSScriptRoot/../opencode/rules" -File -Filter *.md | ForEach-Object {
    New-Symlink -SourcePath $_.FullName -TargetPath "$HOME/.grok/rules/$($_.Name)" -Label "Rule $($_.BaseName) (Grok)"
    New-Symlink -SourcePath $_.FullName -TargetPath "$HOME/.claude/rules/$($_.Name)" -Label "Rule $($_.BaseName) (Claude)"
}

# Slash commands: Claude's user commands dir. Grok also scans ~/.claude/commands.
$commandsDir = "$PSScriptRoot/../opencode/commands"
if (Test-Path -LiteralPath $commandsDir) {
    Get-ChildItem -LiteralPath $commandsDir -File -Filter *.md | ForEach-Object {
        New-Symlink -SourcePath $_.FullName -TargetPath "$HOME/.claude/commands/$($_.Name)" -Label "Command $($_.BaseName)"
    }
}
