#!/bin/zsh
set -e
set -u
set -o pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

if ! command -v brew >/dev/null 2>&1; then
  echo "brew command not found"
  exit 127
fi

echo "Updating Homebrew"
brew update

echo "Upgrading Homebrew packages"
brew upgrade

echo "Homebrew update completed"
