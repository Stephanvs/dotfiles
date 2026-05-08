#!/bin/zsh
source "$DOTFILES/lib/install.zsh"

post_install "zsh \"$DOTFILES/brew/schedule-brew-updatetask.darwin.zsh\""
post_install "zsh \"$DOTFILES/brew/schedule-brew-backuptask.darwin.zsh\""
