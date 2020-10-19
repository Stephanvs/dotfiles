#!/bin/zsh
mkdir -p $HOME/.config
ln -n -f --symbolic $DOTFILES/sxhkd $HOME/.config
