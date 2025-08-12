#!/bin/bash

# Detect OS
OS=$(uname)

if [ "$OS" = "Darwin" ]; then
  # macOS
  if defaults read -g AppleInterfaceStyle 2>/dev/null | grep -qi '^Dark$'; then
    THEME="dark"
    NEW_FLAVOR="mocha"
  else
    THEME="light"
    NEW_FLAVOR="latte"
  fi
elif [ "$OS" = "Linux" ]; then
  # Linux (GNOME example)
  if gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | grep -q 'prefer-dark'; then
    THEME="dark"
    NEW_FLAVOR="mocha"
  else
    THEME="light"
    NEW_FLAVOR="latte"
  fi
else
  # Default to light
  THEME="light"
  NEW_FLAVOR="latte"
fi

# Get current flavor to check if change is needed
CURRENT_FLAVOR=$(tmux show-options -gv @catppuccin_flavor 2>/dev/null || echo "")

# Only proceed if flavor needs to change
if [ "$CURRENT_FLAVOR" = "$NEW_FLAVOR" ]; then
  tmux display-message "Theme already set to $THEME mode ($NEW_FLAVOR)"
  exit 0
fi

# Option A: Unset all @thm_* color variables to force reload
echo "Switching theme from $CURRENT_FLAVOR to $NEW_FLAVOR..."

# Dynamically get all @thm_* variables currently set in tmux and unset them
tmux show-options -g | grep "^@thm_" | cut -d' ' -f1 | while read -r var; do
  tmux set -ug "$var" 2>/dev/null
done

# Set new catppuccin flavor
tmux set -g @catppuccin_flavor "$NEW_FLAVOR"

# Reload the catppuccin plugin to apply the new flavor
if tmux run-shell ~/.tmux/plugins/tmux/catppuccin.tmux; then
  # Option A succeeded
  tmux display-message "Theme switched to $THEME mode ($NEW_FLAVOR)"
else
  # Option B: Fallback to complete config reload
  echo "Plugin reload failed, falling back to complete config reload..."
  if tmux source-file "$DOTFILES/tmux/tmux.conf"; then
    tmux display-message "Theme switched to $THEME mode ($NEW_FLAVOR) - used fallback reload"
  else
    tmux display-message "Theme switch failed - please reload tmux manually"
    exit 1
  fi
fi
