#!/bin/zsh
source $DOTFILES/lib/install.zsh

dest="$HOME/.config/hypr"

for file in "$DOTFILES/hypr/"*.conf; do
  [[ -f "$file" ]] || continue
  symlink "hypr/$(basename "$file")" "$dest/$(basename "$file")"
done
