#!/usr/bin/env bash
set -euo pipefail

printf 'Kernel: %s\n' "$(uname -r)"
for name in sys_vendor product_name bios_version; do
    if [[ -r /sys/class/dmi/id/$name ]]; then
        printf '%s: %s\n' "$name" "$(cat "/sys/class/dmi/id/$name")"
    fi
done
printf 'Kernel command line: %s\n' "$(cat /proc/cmdline)"

found=0
for device in /sys/bus/pci/devices/*; do
    [[ -r "$device/vendor" && -r "$device/class" ]] || continue
    [[ $(cat "$device/vendor") == 0x8086 ]] || continue
    [[ $(cat "$device/class") == 0x03* ]] || continue
    found=1
    address=${device##*/}
    printf '\nIntel display controller: %s\n' "$address"
    if command -v lspci >/dev/null; then lspci -nnk -s "$address"; fi
    if [[ -L "$device/iommu_group" ]]; then
        group=$(readlink -f "$device/iommu_group")
        printf 'IOMMU group: %s\n' "${group##*/}"
        printf 'Group members:\n'
        for member in "$group/devices"/*; do printf '  %s\n' "${member##*/}"; done
    else
        printf 'IOMMU group: not exposed\n'
    fi
    for attribute in sriov_totalvfs sriov_numvfs; do
        if [[ -r "$device/$attribute" ]]; then
            printf '%s: %s\n' "$attribute" "$(cat "$device/$attribute")"
        else
            printf '%s: not exposed by the current firmware and driver\n' "$attribute"
        fi
    done
done

if (( ! found )); then
    printf '\nNo physical Intel display controller found. Run this on the Framework, not inside the rehearsal VM.\n'
    exit 2
fi
printf '\nThis is a read-only hardware report. It does not prove Windows driver compatibility or Prepar3D performance.\n'
