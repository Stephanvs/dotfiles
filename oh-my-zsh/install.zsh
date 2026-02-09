#!/bin/zsh
source $DOTFILES/lib/install.zsh

if [[ -s "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; then
    success "oh-my-zsh is already available"
    exit 0
fi

RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
