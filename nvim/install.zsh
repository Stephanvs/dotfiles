#!/bin/zsh
source $DOTFILES/lib/install.zsh

rm -rf "$HOME/.config/nvim"
symlink nvim/nvchad "$HOME/.config/nvim"
