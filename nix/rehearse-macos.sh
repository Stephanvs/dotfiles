#!/usr/bin/env bash
set -euo pipefail

action=${1:-web}
repo=$(cd "$(dirname "$0")/.." && pwd)
builder=${NIXOS_REHEARSAL_BUILDER:-nixos-preview-builder}
state=${NIXOS_REHEARSAL_MACOS_DIR:-"$repo/.nixos-vm/macos"}
url='http://127.0.0.1:6080/vnc.html?host=127.0.0.1&port=5701&encrypt=0&autoconnect=1&resize=scale&path='
mkdir -p "$state"
state=$(cd "$state" && pwd)

require() { command -v "$1" >/dev/null || { printf 'Required command is missing: %s\n' "$1" >&2; exit 1; }; }
require python3

running() {
    [[ -f "$state/current/vm.pid" ]] || return 1
    local pid
    pid=$(cat "$state/current/vm.pid")
    kill -0 "$pid" 2>/dev/null && ps -p "$pid" -o command= | grep -Fq "$state/current/qmp.sock"
}

build() {
    require orb
    if ! orbctl list -q | grep -Fxq "$builder"; then
        orbctl create nixos:25.11 "$builder"
    fi
    orb -m "$builder" bash "$repo/nix/build-macos.sh" "$1" "$repo" 2>&1 | tee "$state/build.log"
    if [[ "$1" == check ]]; then return; fi
    local bundle identifier image_dir
    bundle=$(orb -m "$builder" readlink -f /home/stephanvs/nixos-rehearsal-macos/result)
    identifier=$(basename "$bundle")
    image_dir="$state/images/$identifier"
    if [[ ! -f "$image_dir/.complete" ]]; then
        mkdir -p "$image_dir"
        orb -m "$builder" tar -ch -C "$bundle" disk.qcow2 efi-code.fd efi-vars.fd novnc | tar -x -C "$image_dir"
        touch "$image_dir/.complete"
    fi
    ln -sfn "$image_dir" "$state/latest"
    if ! running; then ln -sfn "$image_dir" "$state/current"; fi
}

serve() {
    if [[ ! -f "$state/web.pid" ]] ||
       ! kill -0 "$(cat "$state/web.pid")" 2>/dev/null ||
       ! ps -p "$(cat "$state/web.pid")" -o command= | grep -Fq -- "--directory $state/current/novnc"; then
        python3 - "$state/web.pid" "$state/web.log" "$state/current/novnc" <<'PYTHON'
import subprocess
import sys
from pathlib import Path
with open(sys.argv[2], "ab") as log:
    process = subprocess.Popen([sys.executable, "-m", "http.server", "6080",
                                "--bind", "127.0.0.1", "--directory", sys.argv[3]],
                               stdin=subprocess.DEVNULL, stdout=log,
                               stderr=subprocess.STDOUT, start_new_session=True)
Path(sys.argv[1]).write_text(str(process.pid) + "\n")
PYTHON
    fi
    python3 - <<'PYTHON'
import time
import urllib.request
for attempt in range(20):
    try:
        with urllib.request.urlopen("http://127.0.0.1:6080/vnc.html", timeout=1) as response:
            if response.status == 200:
                break
    except OSError:
        time.sleep(0.1)
else:
    raise RuntimeError("The local browser console did not start")
PYTHON
}

launch() {
    require qemu-system-aarch64
    require qemu-img
    [[ $(uname -s) == Darwin && $(uname -m) == arm64 ]] || {
        printf 'This launcher requires an Apple Silicon Mac.\n' >&2; exit 1;
    }
    if running; then serve; printf 'NixOS is already running: %s\n' "$url"; return; fi
    if [[ ! -f "$state/latest/.complete" ]]; then build build; fi
    ln -sfn "$(cd "$state/latest" && pwd -P)" "$state/current"
    local image_dir
    image_dir=$(cd "$state/current" && pwd -P)
    if [[ ! -f "$state/current/guest.qcow2" ]]; then
        qemu-img create -f qcow2 -F qcow2 -b "$image_dir/disk.qcow2" "$state/current/guest.qcow2" 48G
    fi
    local firmware_dir
    firmware_dir=${NIXOS_REHEARSAL_FIRMWARE_DIR:-"$(dirname "$(command -v qemu-system-aarch64)")/../share/qemu"}
    [[ -f "$firmware_dir/edk2-aarch64-code.fd" && -f "$firmware_dir/edk2-arm-vars.fd" ]] || {
        printf 'QEMU ARM firmware is missing from %s\n' "$firmware_dir" >&2; exit 1;
    }
    if [[ ! -f "$state/current/guest-efi.fd" ]]; then cp "$firmware_dir/edk2-arm-vars.fd" "$state/current/guest-efi.fd"; fi
    chmod u+w "$state/current/guest-efi.fd"
    rm -f "$state/current/qmp.sock" "$state/current/vm.pid"
    local launch_pid
    launch_pid=$(python3 - "$state/current/qemu.log" qemu-system-aarch64 \
        -name 'NixOS rehearsal' -machine virt,gic-version=3 -accel hvf -cpu host -smp 4 -m 8192 \
        -device virtio-rng-pci -device virtio-gpu-pci \
        -device qemu-xhci -device usb-kbd -device usb-tablet \
        -drive "if=pflash,format=raw,unit=0,readonly=on,file=$firmware_dir/edk2-aarch64-code.fd" \
        -drive "if=pflash,format=raw,unit=1,file=$state/current/guest-efi.fd" \
        -drive "if=none,id=root,format=qcow2,file=$state/current/guest.qcow2" \
        -device virtio-blk-pci,drive=root,serial=root,bootindex=1 \
        -netdev user,id=net0,hostfwd=tcp:127.0.0.1:2222-:22 -device virtio-net-pci,netdev=net0 \
        -audiodev coreaudio,id=audio0 -device virtio-sound-pci,audiodev=audio0 \
        -display none -vnc 127.0.0.1:1,websocket=5701 \
        -serial "file:$state/current/boot.log" -monitor none \
        -qmp "unix:$state/current/qmp.sock,server=on,wait=off" \
        -pidfile "$state/current/vm.pid" <<'PYTHON'
import subprocess
import sys
with open(sys.argv[1], "ab") as log:
    process = subprocess.Popen(sys.argv[2:], stdin=subprocess.DEVNULL,
                               stdout=log, stderr=subprocess.STDOUT,
                               start_new_session=True)
print(process.pid)
PYTHON
    )
    sleep 1
    if ! kill -0 "$launch_pid" 2>/dev/null || ! running; then
        cat "$state/current/qemu.log" >&2
        exit 1
    fi
    serve
    printf 'NixOS desktop: %s\n' "$url"
}

case "$action" in
    check|build) build "$action" ;;
    web|run|start) launch ;;
    status)
        if running; then printf 'NixOS is running: %s\n' "$url"; else printf 'NixOS is stopped.\n'; fi
        ;;
    verify)
        launch
        printf '#!/bin/sh\nprintf "rehearsal\\n"\n' >"$state/ssh-askpass.sh"
        chmod 700 "$state/ssh-askpass.sh"
        export SSH_ASKPASS="$state/ssh-askpass.sh" SSH_ASKPASS_REQUIRE=force DISPLAY=nixos-preview
        NIXOS_VM_EXTERNAL=1 bash "$repo/nix/verify-vm.sh" "$state/current" "$state/current"
        ;;
    stop)
        if running; then
            python3 - "$state/current/qmp.sock" <<'PYTHON'
import json
import socket
import sys
with socket.socket(socket.AF_UNIX) as connection:
    connection.connect(sys.argv[1])
    stream = connection.makefile("rwb")
    stream.readline()
    for command in ["qmp_capabilities", "system_powerdown"]:
        stream.write(json.dumps({"execute": command}).encode() + b"\n")
        stream.flush()
        while True:
            message = json.loads(stream.readline())
            if "error" in message:
                raise RuntimeError(message["error"])
            if "return" in message:
                break
PYTHON
            printf 'Requested a clean guest shutdown.\n'
            for _ in {1..30}; do
                running || break
                sleep 1
            done
            if running; then
                printf 'The guest is still shutting down; check status before starting it again.\n' >&2
                exit 1
            fi
        fi
        if [[ -f "$state/web.pid" ]]; then
            web_pid=$(cat "$state/web.pid")
            if ps -p "$web_pid" -o command= | grep -Fq -- "--directory $state/current/novnc"; then
                kill "$web_pid"
            fi
            rm -f "$state/web.pid"
        fi
        printf 'NixOS and the browser server are stopped.\n'
        ;;
    *) printf 'Usage: %s {check|build|web|verify|status|stop}\n' "$0" >&2; exit 2 ;;
esac
