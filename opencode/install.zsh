#!/bin/zsh
source $DOTFILES/lib/install.zsh

symlink opencode/opencode.json "$HOME/.config/opencode/opencode.json"
symlink opencode/AGENTS.md "$HOME/.config/opencode/AGENTS.md"

# directories
symlink opencode/prompts "$HOME/.config/opencode/prompts"
symlink opencode/skills "$HOME/.config/opencode/skills"
symlink opencode/rules "$HOME/.config/opencode/rules"
symlink opencode/themes "$HOME/.config/opencode/themes"
symlink opencode/command "$HOME/.config/opencode/command"
