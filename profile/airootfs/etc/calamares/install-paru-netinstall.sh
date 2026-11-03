#!/usr/bin/bash
set -Eeuo pipefail
exec >> /var/log/archforge-paru-install.log 2>&1
set -x

echo "===== Paru installation started: $(date) ====="

trap 'status=$?; echo "===== Paru installation exited with status $status ====="' EXIT

build_user="archforge-build"
build_home="/home/$build_user"

# Install only what's needed to build the package.
pacman -S --needed --noconfirm git base-devel

if pacman -Q paru-bin >/dev/null 2>&1; then
    exit 0
fi

useradd --create-home --user-group --shell /bin/bash "$build_user"

cleanup() {
    userdel --remove "$build_user" 2>/dev/null || true
    rm -rf "$build_home"
}
trap cleanup EXIT

# Build the package using its precompiled upstream binary.
runuser -u "$build_user" -- env \
    HOME="$build_home" \
    XDG_CACHE_HOME="$build_home/.cache" \
    /usr/bin/bash -c '
        set -Eeuo pipefail
        git clone https://aur.archlinux.org/paru-bin.git "$HOME/paru-bin"
        cd "$HOME/paru-bin"
        makepkg --noconfirm
    '

pkg="$(find "$build_home/paru-bin" \
    -maxdepth 1 \
    -type f \
    -name "paru-bin-[0-9]*.pkg.tar.zst" \
    -print -quit)"

if [[ -z "$pkg" ]]; then
    echo "ERROR: paru-bin package was not produced." >&2
    exit 1
fi

pacman -U --noconfirm "$pkg"
