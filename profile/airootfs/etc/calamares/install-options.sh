
#!/usr/bin/bash
set -Eeuo pipefail

gpu_selection="${1-}"
software_selection="${2-}"
target="${3:?Missing installation root}"
config="/etc/calamares/target-pacman.conf"

contains() {
    [[ ",$1," == *",$2,"* ]]
}

# Enable multilib in the installed system.
enable_target_multilib() {
    local pacman_conf="$target/etc/pacman.conf"

    if [[ ! -f "$pacman_conf" ]]; then
        echo "ERROR: Target pacman.conf not found: $pacman_conf" >&2
        return 1
    fi

    if ! /usr/bin/grep -Eq '^[[:space:]]*\[multilib\][[:space:]]*$' "$pacman_conf"; then
        cat >> "$pacman_conf" <<'EOF'

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF
    fi
}

enable_target_multilib

declare -A added=()
packages=()

add_packages() {
    local package
    for package in "$@"; do
        if [[ -z "${added[$package]+x}" ]]; then
            added[$package]=1
            packages+=("$package")
        fi
    done
}

add_amd() {
    add_packages mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon rocm-opencl-runtime opencl-mesa
}

add_intel() {
    add_packages mesa lib32-mesa vulkan-intel lib32-vulkan-intel intel-media-driver intel-compute-runtime
}

add_virtio() {
    add_packages mesa lib32-mesa vulkan-virtio lib32-vulkan-virtio
}

add_nouveau() {
    add_packages mesa lib32-mesa vulkan-nouveau lib32-vulkan-nouveau
}

add_nvidia() {
    add_packages nvidia-open nvidia-utils lib32-nvidia-utils opencl-nvidia lib32-opencl-nvidia nvidia-settings nvidia-prime
}

install_legacy_nvidia() {
    local branch="$1"
    local aur_user="archforge-aur"
    local -a aur_packages
    local -a bootstrap_packages=(dkms linux-headers)

    case "$branch" in
        580)
            bootstrap_packages+=(lib32-zlib lib32-libglvnd)
            aur_packages=(
                nvidia-580xx-dkms
                nvidia-580xx-utils
                lib32-nvidia-580xx-utils
                opencl-nvidia-580xx
                lib32-opencl-nvidia-580xx
                nvidia-580xx-settings
            )
            ;;
        470)
            bootstrap_packages+=(lib32-zlib lib32-libglvnd)
            aur_packages=(
                nvidia-470xx-dkms
                nvidia-470xx-utils
                lib32-nvidia-470xx-utils
                opencl-nvidia-470xx
                nvidia-470xx-settings
            )
            ;;
        390)
            aur_packages=(
                nvidia-390xx-dkms
                nvidia-390xx-utils
                opencl-nvidia-390xx
                nvidia-390xx-settings
            )
            ;;
        340)
            aur_packages=(
                nvidia-340xx-dkms
                nvidia-340xx-utils
                opencl-nvidia-340xx
            )
            ;;
        *)
            echo "Unknown NVIDIA legacy branch: $branch" >&2
            return 1
            ;;
    esac

    echo "Installing prerequisites for NVIDIA ${branch}xx:"
    printf '  %s\n' "${bootstrap_packages[@]}"

    /usr/bin/pacstrap -C "$config" "$target" "${bootstrap_packages[@]}"

    if /usr/bin/arch-chroot "$target" /usr/bin/id "$aur_user" >/dev/null 2>&1; then
        echo "Temporary AUR account already exists; refusing to reuse it." >&2
        return 1
    fi

    /usr/bin/arch-chroot "$target" \
        /usr/bin/useradd --create-home --user-group --groups wheel "$aur_user"

    cleanup_aur_user() {
        /usr/bin/arch-chroot "$target" \
            /usr/bin/userdel --remove "$aur_user" >/dev/null 2>&1 || true
    }
    trap cleanup_aur_user RETURN

    echo "Installing NVIDIA ${branch}xx packages from the AUR:"
    printf '  %s\n' "${aur_packages[@]}"

    /usr/bin/arch-chroot -u "$aur_user" "$target" \
        /usr/bin/env \
        HOME="/home/$aur_user" \
        CARGO_HOME="/home/$aur_user/.cargo" \
        XDG_CACHE_HOME="/home/$aur_user/.cache" \
        /usr/bin/paru -S --needed --noconfirm "${aur_packages[@]}"

    cleanup_aur_user
    trap - RETURN
}

# NVIDIA driver branches are mutually exclusive.
nvidia_branch_count=0
selected_nvidia_branch=""

for branch in 580 470 390 340; do
    if contains "$gpu_selection" "nvidia-$branch"; then
        ((nvidia_branch_count += 1))
        selected_nvidia_branch="$branch"
    fi
done

if ((nvidia_branch_count > 1)); then
    echo "Select only one NVIDIA driver branch." >&2
    exit 1
fi

if contains "$gpu_selection" nvidia-current && ((nvidia_branch_count > 0)); then
    echo "Do not select both current and legacy NVIDIA drivers." >&2
    exit 1
fi

proprietary_nvidia_selected=0

if contains "$gpu_selection" nvidia-current || ((nvidia_branch_count == 1)); then
    proprietary_nvidia_selected=1
fi

# Automatically detect installed hardware.
if contains "$gpu_selection" auto; then
    while IFS= read -r vendor; do
        case "$vendor" in
            1002) add_amd ;;
            8086) add_intel ;;
            1af4) add_virtio ;;
            10de)
                if ((proprietary_nvidia_selected == 0)); then
                    add_nouveau
                fi
                ;;
        esac
    done < <(
        /usr/bin/lspci -n |
        /usr/bin/awk '$2 ~ /^03/ { split($3, id, ":"); print id[1] }' |
        /usr/bin/sort -u
    )
fi

# Apply manually selected drivers.
contains "$gpu_selection" amd && add_amd
contains "$gpu_selection" intel && add_intel
contains "$gpu_selection" virtio && add_virtio
contains "$gpu_selection" nvidia-current && add_nvidia

# Install official-repository graphics packages.
if ((${#packages[@]})); then
    add_packages vulkan-tools clinfo mesa-utils

    echo "Installing selected graphics packages:"
    printf '  %s\n' "${packages[@]}"

    /usr/bin/pacstrap -C "$config" "$target" "${packages[@]}"
fi

# Install the selected legacy NVIDIA driver.
if ((nvidia_branch_count == 1)); then
    install_legacy_nvidia "$selected_nvidia_branch"
fi

# Always install Steam after the graphics providers.
if [[ -z "${added[vulkan-radeon]+x}" &&
      -z "${added[vulkan-intel]+x}" &&
      -z "${added[vulkan-virtio]+x}" &&
      -z "${added[vulkan-nouveau]+x}" ]] &&
   ! contains "$gpu_selection" nvidia-current &&
   ((nvidia_branch_count == 0)); then
    echo "No GPU driver selected; installing software Vulkan fallback."
    /usr/bin/pacstrap -C "$config" "$target" vulkan-swrast lib32-vulkan-swrast
fi

if [[ "$selected_nvidia_branch" == "390" ||
      "$selected_nvidia_branch" == "340" ]]; then
    echo "WARNING: NVIDIA ${selected_nvidia_branch}xx does not provide Vulkan." >&2
fi

echo "Installing Steam."
/usr/bin/pacstrap -C "$config" "$target" steam

