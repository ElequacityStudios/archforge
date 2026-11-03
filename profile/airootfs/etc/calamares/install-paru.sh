
#!/usr/bin/bash
set -Eeuo pipefail

target="${1:?Missing installation root}"

if [[ ! -d "$target/etc" ]]; then
    echo "Invalid installation root: $target" >&2
    exit 1
fi

arch_chroot=(/usr/bin/arch-chroot "$target")

cleanup() {
    set +e

    echo "Cleaning up Paru build environment."

    "${arch_chroot[@]}" /usr/bin/userdel -r archforge-build \
        >/dev/null 2>&1

    "${arch_chroot[@]}" /usr/bin/pacman -Rns --noconfirm rust \
        >/dev/null 2>&1
}

trap cleanup EXIT

echo "Installing Paru build dependencies."

"${arch_chroot[@]}" /usr/bin/pacman -S --needed --noconfirm \
    git rust base-devel

echo "Creating temporary build user."

"${arch_chroot[@]}" /usr/bin/useradd \
    --create-home \
    --shell /bin/bash \
    archforge-build

echo "Building Paru from the AUR."

"${arch_chroot[@]}" /usr/bin/runuser -u archforge-build -- \
    /usr/bin/bash -lc '
        set -Eeuo pipefail

        export HOME=/home/archforge-build
        export CARGO_HOME="$HOME/.cargo"
        export XDG_CACHE_HOME="$HOME/.cache"
        export CARGO_BUILD_JOBS=2
        export CARGO_PROFILE_RELEASE_LTO=false

        git clone https://aur.archlinux.org/paru.git \
            "$HOME/paru-build"

        cd "$HOME/paru-build"

        makepkg --noconfirm
    '

build_dir="$target/home/archforge-build/paru-build"

mapfile -t packages < <(
    /usr/bin/find "$build_dir" \
        -maxdepth 1 \
        -type f \
        -name 'paru-[0-9]*.pkg.tar.zst'
)

if (( ${#packages[@]} != 1 )); then
    echo "Expected exactly one Paru package; found ${#packages[@]}." >&2
    exit 1
fi

package_name="${packages[0]##*/}"

echo "Installing $package_name."

"${arch_chroot[@]}" /usr/bin/pacman -U --noconfirm \
    "/home/archforge-build/paru-build/$package_name"

echo "Verifying Paru installation."

"${arch_chroot[@]}" /usr/bin/pacman -Q paru

echo "Paru installed successfully."

