#!/bin/zsh
source $DOTFILES/lib/install.zsh

symlink tmux/tmux.conf "$HOME/.tmux.conf"

if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    ensure_dir "$HOME/.tmux/plugins"
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

post_install "zsh \"$DOTFILES/tmux/post_update_powerkit_patch.zsh\""
