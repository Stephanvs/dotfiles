#!/bin/zsh
source $DOTFILES/lib/install.zsh

vault_path="$HOME/Documents/Obsidian Vault"
ensure_dir "$vault_path"

symlink obsidian "$vault_path/.obsidian" true
