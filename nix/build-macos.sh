#!/usr/bin/env bash
set -euo pipefail

action=${1:-build}
repo=${2:?Repository path is required}
state="$HOME/nixos-rehearsal-macos"
mkdir -p "$state"
source_dir=$(mktemp -d "$state/source.XXXXXXXX")

# Stage only the declared configuration inputs, excluding credentials and state.
cp "$repo/flake.nix" "$repo/flake.lock" "$source_dir/"
for directory in nix git ghostty hypr zsh starship nvim tmux; do
    cp -R "$repo/$directory" "$source_dir/"
done
mkdir -p "$source_dir/wallpapers" "$source_dir/fonts"
cp "$repo/wallpapers/a-chosen-soul.jpg" "$source_dir/wallpapers/"
cp -R "$repo/fonts/berkeley-mono-nerd-font" "$source_dir/fonts/"
nix_cmd() { nix --extra-experimental-features 'nix-command flakes' "$@"; }

case "$action" in
    check)
        nix_cmd eval --raw "path:$source_dir#nixosConfigurations.rehearsal-macos.config.system.build.toplevel.drvPath"
        ;;
    build)
        nix_cmd build "path:$source_dir#macos-preview" --out-link "$state/result" --max-jobs 2 --cores 4
        ;;
    *) printf 'Unknown builder action: %s\n' "$action" >&2; exit 2 ;;
esac
