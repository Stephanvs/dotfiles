#!/bin/zsh
source $DOTFILES/lib/install.zsh

# Thanks and shout out to https://macos-defaults.com for some of these.
# TODO: take a look at "com.apple.AppleMultitouchTrackpad" for trackpad settings

# Configure Dock
defaults write com.apple.dock "autohide" -bool TRUE
defaults write com.apple.dock "autohide-time-modifier" -float "0.2"
defaults write com.apple.dock "tilesize" -int 40
defaults write com.apple.dock "largesize" -int 80
defaults write com.apple.dock "magnification" -bool TRUE
defaults write com.apple.dock "mineffect" -string "scale"
defaults write com.apple.dock "minimize-to-application" -bool TRUE

# keep Spaces in their assigned order instead or mru
defaults write com.apple.dock "mru-spaces" -bool "false"

# Hide macOS menu bar for SketchyBar ("Always")
defaults write NSGlobalDomain "_HIHideMenuBar" -bool TRUE
defaults write NSGlobalDomain "AppleMenuBarVisibleInFullscreen" -bool FALSE
killall Dock

# Configure Finder
defaults write NSGlobalDomain "AppleShowAllExtensions" -bool "true"
defaults write com.apple.finder "AppleShowAllFiles" -bool "true"
defaults write com.apple.finder "ShowPathbar" -bool "true"
defaults write com.apple.finder "FXPreferredViewStyle" -string "clmv" # set to column view
defaults write com.apple.finder "_FXSortFoldersFirst" -bool "true"
killall Finder

# None of that lazy keyboard stuff, gimme faaaast
defaults write -g InitialKeyRepeat -int 10  # via ui minimum is 15!
defaults write -g KeyRepeat -int 2          # (15ms) via ui minimum is 2 (30ms)

# Install fonts
brew install --cask font-iosevka-nerd-font
brew install --cask font-jetbrains-mono-nerd-font

# Speed up mouse movement
defaults write -g com.apple.mouse.scaling 5.0
