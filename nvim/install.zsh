# nuke nvim dir first
rm -rf $HOME/.config/nvim

# create new symbolic link
ln -nfs $DOTFILES/nvim/config $HOME/.config/nvim
