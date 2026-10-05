#!/usr/bin/env bash
set -euo pipefail

result=$(readlink -f "$1")
run_dir=$2
cd "$run_dir"

novnc --listen 127.0.0.1:6080 --vnc 127.0.0.1:5901 >web-console.log 2>&1 &
console_pid=$!
trap 'kill "$console_pid" 2>/dev/null || true' EXIT
sleep 1
if ! kill -0 "$console_pid" 2>/dev/null; then
    cat web-console.log
    exit 1
fi

printf 'Desktop console: http://localhost:6080/vnc.html?autoconnect=1&resize=scale\n'
export QEMU_OPTS="${QEMU_OPTS:-} -display none -vnc 127.0.0.1:1"
"$result/bin/run-nixos-rehearsal-vm"
