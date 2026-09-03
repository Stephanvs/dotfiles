#!/bin/zsh
source $DOTFILES/lib/install.zsh

symlink opencode/opencode.json "$HOME/.config/opencode/opencode.json"
symlink opencode/cli.json "$HOME/.config/opencode/cli.json"
symlink opencode/AGENTS.md "$HOME/.config/opencode/AGENTS.md"

# directories
symlink opencode/prompts "$HOME/.config/opencode/prompts"
symlink opencode/rules "$HOME/.config/opencode/rules"
symlink opencode/themes "$HOME/.config/opencode/themes"
symlink opencode/commands "$HOME/.config/opencode/commands"
