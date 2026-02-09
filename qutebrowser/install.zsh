#!/bin/zsh
source $DOTFILES/lib/install.zsh

case "$OSTYPE" in
    darwin*)
        symlink qutebrowser/config.py "$HOME/.qutebrowser/config.py"
        if [[ ! -d "$HOME/.qutebrowser/catppuccin" ]]; then
            git clone https://github.com/catppuccin/qutebrowser.git "$HOME/.qutebrowser/catppuccin"
        fi
        ;;
    linux*)
        symlink qutebrowser/config.py "$HOME/.config/qutebrowser/config.py"
        if [[ ! -d "$HOME/.config/qutebrowser/catppuccin" ]]; then
            git clone https://github.com/catppuccin/qutebrowser.git "$HOME/.config/qutebrowser/catppuccin"
        fi
        ;;
    *)
        warn "OS not supported"
        ;;
esac
