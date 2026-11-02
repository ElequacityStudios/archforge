#!/usr/bin/bash
set -euo pipefail

mirrorlist=/etc/pacman.d/mirrorlist
backup="$(mktemp)"
cp "$mirrorlist" "$backup"

if /usr/bin/reflector --latest 20 --age 24 --protocol https --sort rate --save "$mirrorlist" && grep -qE "^[[:space:]]*Server[[:space:]]*=" "$mirrorlist"; then
    echo "Archforge: successfully ranked Arch mirrors by download speed."
    rm -f "$backup"
else
    echo "Archforge: mirror ranking failed; restoring original mirrorlist."
    cp "$backup" "$mirrorlist"
    rm -f "$backup"
fi
