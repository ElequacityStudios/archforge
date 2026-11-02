#!/usr/bin/bash
set -Eeuo pipefail

target="${1:?Missing installation root}"
build_dir="/home/archforge-build/paru-build"

# Install temporary build dependencies.
arch-chroot "$target" pacman -S --needed --noconfirm git rust

# Create an unprivileged build account.
arch-chroot "$target" useradd \
    --create-home --user-group --shell /bin/bash archforge-build

cleanup() {
    arch-chroot "$target" userdel --remove archforge-build 2>/dev/null || true
    rm -rf "$target/home/archforge-build"
}
trap cleanup EXIT

# Build paru in the user's persistent home directory.
arch-chroot -u archforge-build "$target" \
    /usr/bin/env \
    HOME=/home/archforge-build \
    CARGO_HOME=/home/archforge-build/.cargo \
    XDG_CACHE_HOME=/home/archforge-build/.cache \
    CARGO_BUILD_JOBS=1 \
    CARGO_PROFILE_RELEASE_LTO=false \
    CARGO_PROFILE_RELEASE_CODEGEN_UNITS=16 \
    /usr/bin/bash -c '
        git clone https://aur.archlinux.org/paru.git "$HOME/paru-build" &&
        cd "$HOME/paru-build" &&
        makepkg --noconfirm
    '

# Locate and install the built paru package.
arch-chroot "$target" /usr/bin/bash -c '
    pkg=$(find /home/archforge-build/paru-build \
        -maxdepth 1 -type f \
        -name "paru-[0-9]*.pkg.tar.zst" \
        -print -quit)

    if [[ -z "$pkg" ]]; then
        echo "ERROR: paru package was not produced." >&2
        exit 1
    fi

    pacman -U --noconfirm "$pkg"
'

# Remove temporary Rust dependencies.
arch-chroot "$target" pacman -Rns --noconfirm rust
