#!/usr/bin/bash
set -Eeuo pipefail

target="${1:?Missing installation root}"
marker="$target/var/lib/archforge/paru-selected"

# Keep Paru if the user selected it in NetInstall.
if [[ -e "$marker" ]]; then
    rm -f "$marker"
    exit 0
fi

# Otherwise, remove Paru if it was temporarily installed
# for a legacy NVIDIA driver.
if /usr/bin/arch-chroot "$target" \
    /usr/bin/pacman -Q paru >/dev/null 2>&1; then

    /usr/bin/arch-chroot "$target" \
        /usr/bin/pacman -Rns --noconfirm paru
fi
