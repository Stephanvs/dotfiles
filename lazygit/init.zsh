alias lg='lazygit'

# Symlink lazygit config if lazygit is installed
if command -v lazygit &> /dev/null; then
  # macOS uses ~/Library/Application Support/lazygit
  # Linux uses ~/.config/lazygit
  if [[ "$OSTYPE" == "darwin"* ]]; then
    LAZYGIT_CONFIG_DIR="$HOME/Library/Application Support/lazygit"
  else
    LAZYGIT_CONFIG_DIR="$HOME/.config/lazygit"
  fi

  mkdir -p "$LAZYGIT_CONFIG_DIR"
  ln -nfs "$DOTFILES/lazygit/config.yml" "$LAZYGIT_CONFIG_DIR/config.yml"
fi
