#!/bin/zsh
source $DOTFILES/lib/install.zsh

# Canonical skill files live in this module. Each harness only sees them if they
# appear in a directory that harness already scans. ~/.agents/skills is the
# shared user store (Codex, OpenCode, Grok). Claude/Cursor/Gemini do not read
# that path, so they get per-skill links of their own.
skill_roots=(
  "$HOME/.agents/skills"
  "$HOME/.claude/skills"
  "$HOME/.cursor/skills"
  "$HOME/.gemini/skills"
)

for skill_dir in "$DOTFILES"/agents/skills/*(/N); do
  name="${skill_dir:t}"
  for root in "${skill_roots[@]}"; do
    symlink "agents/skills/$name" "$root/$name"
  done
done

# Tech rules stay authored next to OpenCode's AGENTS.md (which references
# @rules/...). Grok and Claude load home-level rules directories.
for rule in "$DOTFILES"/opencode/rules/*.md(N); do
  name="${rule:t}"
  symlink "opencode/rules/$name" "$HOME/.grok/rules/$name"
  symlink "opencode/rules/$name" "$HOME/.claude/rules/$name"
done

# Slash commands: Claude's user commands dir. Grok also scans ~/.claude/commands.
for cmd in "$DOTFILES"/opencode/commands/*.md(N); do
  name="${cmd:t}"
  symlink "opencode/commands/$name" "$HOME/.claude/commands/$name"
done
