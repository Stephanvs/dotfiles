#!/bin/zsh
source $DOTFILES/lib/install.zsh

if command -v zoxide >/dev/null 2>&1; then
    success "zoxide is already available"
else
    post_install "curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh"
fi
