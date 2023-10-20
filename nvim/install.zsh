# nuke nvim dir first
rm -rf $HOME/.config/nvim

# git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1
#
# # link custom config folder inside nvim
# ln -nfs $DOTFILES/nvim/custom $HOME/.config/nvim/lua/custom

# create new symbolic link
ln -nfs $DOTFILES/nvim/config $HOME/.config/nvim

