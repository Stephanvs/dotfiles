#!/bin/zsh
source $DOTFILES/lib/install.zsh

ensure_current_wallpaper() {
  local wallpaper_dir="$DOTFILES/wallpapers"
  local current="$wallpaper_dir/current"
  local default_wallpaper="palm_booster.jpeg"

  if [[ ! -e "$current" && ! -L "$current" ]]; then
    if [[ ! -f "$wallpaper_dir/$default_wallpaper" ]]; then
      warn "Wallpaper not found: $wallpaper_dir/$default_wallpaper"
      return 1
    fi

    if ! ln -s "$default_wallpaper" "$current"; then
      warn "Failed to create wallpaper symlink: $current -> $default_wallpaper"
      return 1
    fi
  fi

  if [[ ! -f "$current" ]]; then
    warn "Wallpaper not found: $current"
    return 1
  fi
}

change_background() {
  FILE="'file://$(readlink -e "$1" )'"

  if [ "$FILE" != "'file://'" ]
  then
      gsettings set org.gnome.desktop.background picture-uri "$FILE"
  else
      warn "File doesn't exist"
  fi
}

ensure_current_wallpaper && change_background "$DOTFILES/wallpapers/current"
