#!/bin/zsh

# Create the destination directory if it doesn't exist
mkdir -p "$HOME/.config/hypr"
$dest = $HOME/.config/hypr

for file in "$DOTFILES/hypr/"*.conf; do
  # check file existing
  [ -f "$file" ] || continue

  echo "linking $file to $HOME/.config/hypr/$(basename "$file")"
  # create symlink
  ln -sf "$file" "$HOME/.config/hypr/$(basename "$file")"
done
