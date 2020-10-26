mkdir -p "$HOME/.local/share"
ln -n --symbolic $DOTFILES/fonts "$HOME/.local/share/fonts"
fc-cache -f -v
