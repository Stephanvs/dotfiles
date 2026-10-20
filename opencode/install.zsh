#!/bin/zsh
source $DOTFILES/lib/install.zsh

npm --prefix "$DOTFILES/opencode/claude-acp" ci --ignore-scripts --no-audit --no-fund || exit 1
npm --prefix "$DOTFILES/opencode/claude-acp" run build || exit 1

symlink opencode/opencode.json "$HOME/.config/opencode/opencode.json"
symlink opencode/cli.json "$HOME/.config/opencode/cli.json"
symlink opencode/AGENTS.md "$HOME/.config/opencode/AGENTS.md"

# directories
symlink opencode/prompts "$HOME/.config/opencode/prompts"
symlink opencode/rules "$HOME/.config/opencode/rules"
symlink opencode/themes "$HOME/.config/opencode/themes"
symlink opencode/commands "$HOME/.config/opencode/commands"
symlink opencode/claude-acp "$HOME/.config/opencode/claude-acp"
