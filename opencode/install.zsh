# remove existing config directory/symlink
rm -rf $HOME/.config/opencode

# create symbolic link to entire opencode directory (GNU Stow-like approach)
ln -nfs $DOTFILES/opencode $HOME/.config/opencode
