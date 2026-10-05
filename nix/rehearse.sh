#!/usr/bin/env bash
set -euo pipefail

action=${1:-check}
repo=${2:-$(cd "$(dirname "$0")/.." && pwd)}
state_dir=${NIXOS_REHEARSAL_DIR:-"$HOME/nixos-rehearsal"}
mkdir -p "$state_dir"
source_dir=$(mktemp -d "$state_dir/source.XXXXXXXX")

# Copy only configuration inputs, never the checkout's local state or credentials.
cp "$repo/flake.nix" "$source_dir/"
if [[ -f "$repo/flake.lock" ]]; then cp "$repo/flake.lock" "$source_dir/"; fi
for directory in nix git ghostty hypr zsh starship nvim tmux; do
    cp -R "$repo/$directory" "$source_dir/"
done
mkdir -p "$source_dir/wallpapers"
cp "$repo/wallpapers/a-chosen-soul.jpg" "$source_dir/wallpapers/"
mkdir -p "$source_dir/fonts"
cp -R "$repo/fonts/berkeley-mono-nerd-font" "$source_dir/fonts/"

nix_cmd() { nix --extra-experimental-features 'nix-command flakes' "$@"; }
nix_cmd flake lock "path:$source_dir"
cp "$source_dir/flake.lock" "$repo/flake.lock"

case "$action" in
    check)
        nix_cmd flake check --no-build "path:$source_dir"
        nix_cmd eval --raw "path:$source_dir#nixosConfigurations.rehearsal.config.system.build.toplevel.drvPath"
        ;;
    build|run|web|verify)
        nix_cmd build "path:$source_dir#rehearsal" --out-link "$state_dir/result"
        run_dir="$state_dir/runs/$(basename "$(readlink -f "$state_dir/result")")"
        mkdir -p "$run_dir"
        # Retain the backing image for this run's persistent QCOW2 overlay.
        nix-store --add-root "$run_dir/result" --indirect --realise "$state_dir/result" >/dev/null
        if [[ "$action" == verify ]]; then
            nix_cmd shell --inputs-from "path:$source_dir" nixpkgs#sshpass nixpkgs#openssh nixpkgs#python3 \
                --command bash "$source_dir/nix/verify-vm.sh" "$state_dir/result" "$run_dir"
        elif [[ "$action" == web ]]; then
            nix_cmd shell --inputs-from "path:$source_dir" nixpkgs#novnc \
                --command bash "$source_dir/nix/run-web.sh" "$state_dir/result" "$run_dir"
        elif [[ "$action" == run ]]; then
            cd "$run_dir"
            exec "$state_dir/result/bin/run-nixos-rehearsal-vm"
        fi
        ;;
    *) printf 'Unknown action: %s\n' "$action" >&2; exit 2 ;;
esac
