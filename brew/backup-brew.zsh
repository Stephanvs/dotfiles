#!/bin/zsh
set -e
set -u
set -o pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

script_dir="${0:A:h}"
dotfiles="${DOTFILES:-${script_dir:h}}"
brewfile_rel="brew/Brewfile"
brewfile="$dotfiles/$brewfile_rel"

if ! command -v brew >/dev/null 2>&1; then
  echo "brew command not found"
  exit 127
fi

if ! command -v git >/dev/null 2>&1; then
  echo "git command not found"
  exit 127
fi

echo "Backing up Homebrew bundle"

cd "$dotfiles"

if [[ -n "$(git status --porcelain -- "$brewfile_rel")" ]]; then
  echo "Skipping backup because $brewfile_rel has uncommitted changes"
  exit 0
fi

tmp_brewfile="$(mktemp "${TMPDIR:-/tmp}/Brewfile.XXXXXX")"

cleanup() {
  rm -f "$tmp_brewfile"
}

trap cleanup EXIT

brew bundle dump --file="$tmp_brewfile" --force

if [[ -f "$brewfile" ]] && cmp -s "$tmp_brewfile" "$brewfile"; then
  echo "Brewfile already up to date"
  exit 0
fi

mkdir -p "$(dirname "$brewfile")"
mv "$tmp_brewfile" "$brewfile"

git add -- "$brewfile_rel"

if git diff --cached --quiet -- "$brewfile_rel"; then
  echo "No Brewfile changes to commit"
  exit 0
fi

git commit -m "chore: backup of homebrew apps" -- "$brewfile_rel"

echo "Backup completed"
