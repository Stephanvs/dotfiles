#!/bin/zsh
ln -f -s $DOTFILES/xresources/profile $HOME/.profile

# Copy xinitrc to .xinitrc, contains settings to initialize Xorg
ln -f -s $DOTFILES/xresources/xinitrc $HOME/.xinitrc
