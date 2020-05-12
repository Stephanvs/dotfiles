#!/bin/bash

change_background() {
  FILE="'file://$(readlink -e "$1" )'"

  if [ "$FILE" != "'file://'" ]
  then
      gsettings set org.gnome.desktop.background picture-uri "$FILE"
  else
      echo "File doesn't exist"
  fi
}

change_background $DOTFILES/wallpapers/dark_gradient.jpg