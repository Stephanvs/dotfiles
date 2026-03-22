#!/bin/zsh
source $DOTFILES/lib/install.zsh

vault_path="$HOME/notes"
ensure_dir "$vault_path"

symlink obsidian "$vault_path/.obsidian" true
