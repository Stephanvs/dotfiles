#!/bin/zsh
source $DOTFILES/lib/install.zsh

change_background() {
  FILE="'file://$(readlink -e "$1" )'"

  if [ "$FILE" != "'file://'" ]
  then
      gsettings set org.gnome.desktop.background picture-uri "$FILE"
  else
      warn "File doesn't exist"
  fi
}

change_background "$DOTFILES/wallpapers/dark_gradient.jpg"
