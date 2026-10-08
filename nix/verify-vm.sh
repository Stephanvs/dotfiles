#!/usr/bin/env bash
set -euo pipefail

result=$(readlink -f "$1")
run_dir=$2
cd "$run_dir"
if [[ ${NIXOS_VM_EXTERNAL:-0} == 1 ]]; then
    vm_pid=$(cat "$run_dir/vm.pid")
else
    export QEMU_OPTS="-display none -qmp unix:$run_dir/qmp.sock,server=on,wait=off"
    "$result/bin/run-nixos-rehearsal-vm" >boot.log 2>&1 &
    vm_pid=$!
fi
export SSHPASS=rehearsal
ssh_options=(-p 2222 -o ConnectTimeout=3 -o StrictHostKeyChecking=accept-new -o "UserKnownHostsFile=$run_dir/known_hosts")
guest() {
    if [[ ${NIXOS_VM_EXTERNAL:-0} == 1 ]]; then
        ssh -o PubkeyAuthentication=no "${ssh_options[@]}" stephanvs@127.0.0.1 "$@"
    else
        sshpass -e ssh "${ssh_options[@]}" stephanvs@127.0.0.1 "$@"
    fi
}

# Invoked by the EXIT trap, including after a failed guest check.
# shellcheck disable=SC2329
cleanup() {
    if [[ ${NIXOS_VM_EXTERNAL:-0} == 1 ]]; then return; fi
    if kill -0 "$vm_pid" 2>/dev/null; then
        guest "printf '%s\\n' rehearsal | sudo -S poweroff" >/dev/null 2>&1 || true
        for _ in {1..15}; do
            kill -0 "$vm_pid" 2>/dev/null || break
            sleep 1
        done
        kill "$vm_pid" 2>/dev/null || true
        wait "$vm_pid" 2>/dev/null || true
    fi
}
trap 'cleanup' EXIT

ready=0
for _ in {1..90}; do
    if ! kill -0 "$vm_pid" 2>/dev/null; then cat boot.log; exit 1; fi
    if guest true >/dev/null 2>&1; then ready=1; break; fi
    sleep 2
done
if (( ! ready )); then tail -100 boot.log; exit 1; fi

guest 'cat > /tmp/nixos-editor-check.lua' <"$(dirname "$0")/verify-editors.lua"
verification_status=0
guest 'bash -l -s' <<'GUEST' 2>&1 | tee verification.log || verification_status=$?
set -euo pipefail
test "$(hostname)" = nixos-rehearsal
test -d /sys/firmware/efi
test "$(findmnt -n -o FSTYPE /)" = ext4
for unit in home-manager-stephanvs.service greetd.service; do
    systemctl is-active "$unit"
done
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
for _ in {1..30}; do
    instance=$(hyprctl instances -j 2>/dev/null | jq -er '.[0].instance // empty' 2>/dev/null || true)
    [[ -n "$instance" ]] && break
    sleep 2
done
export HYPRLAND_INSTANCE_SIGNATURE="$instance"
test -n "$HYPRLAND_INSTANCE_SIGNATURE"
hyprctl configerrors -j | tee /tmp/hyprland-config-errors.json
# Hyprland 0.55 returns [""] when there are no configuration errors.
jq -e 'map(select(test("\\S"))) | length == 0' /tmp/hyprland-config-errors.json
hyprctl monitors -j | jq -e 'length > 0'
wallpaper_unit=hyprpaper.service
if [[ -f "$HOME/.config/systemd/user/nixos-preview-wallpaper.service" ]]; then
    wallpaper_unit=nixos-preview-wallpaper.service
fi
for unit in waybar.service "$wallpaper_unit" hypridle.service; do
    for _ in {1..30}; do
        systemctl --user is-active --quiet "$unit" && break
        sleep 1
    done
    systemctl --user is-active "$unit"
done
notification_id=$(notify-send --print-id --expire-time=0 'NixOS rehearsal' 'Desktop notification check')
makoctl list -j | jq -e --argjson id "$notification_id" \
    'any(.[]; .id == $id and .summary == "NixOS rehearsal" and .body == "Desktop notification check")'
makoctl dismiss -n "$notification_id"
ghostty +validate-config
hyprctl dispatch exec 'uwsm app -- ghostty -e tmux new-session -A -s rehearsal-verify'
for _ in {1..20}; do
    if hyprctl clients -j | jq -e 'any(.[]; .class | ascii_downcase | contains("ghostty"))' >/dev/null; then break; fi
    sleep 1
done
hyprctl clients -j | jq -e 'any(.[]; .class | ascii_downcase | contains("ghostty"))'

work=$(mktemp -d)
for _ in {1..30}; do
    if tmux has-session -t rehearsal-verify 2>/dev/null; then break; fi
    sleep 1
done
tmux has-session -t rehearsal-verify
tmux send-keys -t rehearsal-verify:1.1 -l "printf '%s\\n' 'tmux shell check' > '$work/tmux-result'"
tmux send-keys -t rehearsal-verify:1.1 Enter
for _ in {1..90}; do
    [[ -f "$work/tmux-result" ]] && break
    sleep 1
done
grep -qx 'tmux shell check' "$work/tmux-result"
tmux split-window -h -t rehearsal-verify:1
test "$(tmux list-panes -t rehearsal-verify:1 | wc -l)" -eq 2
sesh list -t | grep -qx rehearsal-verify
cat >"$work/check-editor.sh" <<'EDITOR'
export NIXOS_EDITOR_REPORT="$1/editor-result"
tmux set-option -p -t "$TMUX_PANE" remain-on-exit on
timeout --foreground --kill-after=5s 90s nvim -c 'lua vim.schedule(function() dofile("/tmp/nixos-editor-check.lua") end)'
printf '%s\n' "$?" >"$1/editor-status"
EDITOR
editor_pane=$(tmux new-window -d -P -F '#{pane_id}' -t rehearsal-verify -n editor bash "$work/check-editor.sh" "$work")
for _ in {1..100}; do
    [[ -f "$work/editor-status" ]] && break
    sleep 1
done
if [[ ! -f "$work/editor-result" || ! -f "$work/editor-status" ]] ||
    ! grep -qx 0 "$work/editor-status"; then
    tmux capture-pane -p -t "$editor_pane"
    if [[ -f "$work/editor-result" ]]; then cat "$work/editor-result"; fi
    exit 1
fi
cat "$work/editor-result"
tmux kill-pane -t "$editor_pane"
node -e 'console.log("JavaScript VM check")' | grep -qx 'JavaScript VM check'
printf 'fn main() { println!("Rust VM check"); }\n' >"$work/main.rs"
rustc "$work/main.rs" -o "$work/rust-check"
"$work/rust-check" | grep -qx 'Rust VM check'
DOTNET_NOLOGO=1 DOTNET_CLI_TELEMETRY_OPTOUT=1 dotnet new console -o "$work/dotnet-check" >/dev/null
DOTNET_NOLOGO=1 DOTNET_CLI_TELEMETRY_OPTOUT=1 dotnet run --project "$work/dotnet-check" | grep -qx 'Hello, World!'
printf 'PASS: UEFI boot, Home Manager, Hyprland, desktop services, notifications, Ghostty, tmux, sesh, Neovim and JavaScript/Rust/.NET execution.\n'
GUEST

if (( verification_status )); then
    guest 'journalctl --user -b --no-pager -n 150' >desktop.log 2>&1 || true
fi
python3 - "$run_dir" <<'PYTHON'
import json
import socket
import sys
from pathlib import Path

directory = Path(sys.argv[1])
with socket.socket(socket.AF_UNIX) as connection:
    connection.connect(str(directory / "qmp.sock"))
    stream = connection.makefile("rwb")
    json.loads(stream.readline())
    for request in [
        {"execute": "qmp_capabilities"},
        {"execute": "screendump", "arguments": {"filename": str(directory / "desktop.png"), "format": "png"}},
    ]:
        stream.write(json.dumps(request).encode() + b"\n")
        stream.flush()
        while True:
            response = json.loads(stream.readline())
            if "error" in response:
                raise RuntimeError(response["error"])
            if "return" in response:
                break
print(f"Screenshot: {directory / 'desktop.png'}")
PYTHON
exit "$verification_status"
