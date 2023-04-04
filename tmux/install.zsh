# create new symbolic link
ln -nfs $DOTFILES/tmux/.tmux.conf $HOME/.tmux.conf

if [ ! -d $HOME/.tmux ]; then
    # clone repo to the '.tmux' folder
    git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm
fi
