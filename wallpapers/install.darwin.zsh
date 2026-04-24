#!/bin/zsh
source $DOTFILES/lib/install.zsh

change_background() {
  local wallpaper="$1"

  if [[ ! -f "$wallpaper" ]]; then
    warn "Wallpaper not found: $wallpaper"
    return 1
  fi

  if osascript -e 'on run argv' \
    -e 'tell application "System Events" to tell every desktop to set picture to item 1 of argv' \
    -e 'end run' "$wallpaper"; then
    success "Set wallpaper: $wallpaper"
  else
    warn "Failed to set wallpaper: $wallpaper"
    return 1
  fi
}

change_background "$DOTFILES/wallpapers/wallhaven-oglrv9.jpg"
