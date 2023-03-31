if [[ "$OSTYPE" == "darwin"* ]]; then

  # Fix for keyboard press-and-hold repeat of buttons
  defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false

fi
