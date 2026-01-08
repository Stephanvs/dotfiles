#!/bin/zsh

# Create the destination directory if it doesn't exist
dest="$HOME/.config/hypr"
mkdir -p "$dest"

for file in "$DOTFILES/hypr/"*.conf; do
  # check file existing
  [ -f "$file" ] || continue

  echo "linking $file to $dest/$(basename "$file")"
  # create symlink
  ln -sf "$file" "$dest/$(basename "$file")"
done
