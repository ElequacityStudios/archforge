
#!/usr/bin/bash
set -Eeuo pipefail

target="${1:?Missing installation root}"
package_list="/etc/calamares/packages-installed.x86_64"

if [[ ! -f "$package_list" ]]; then
    echo "Installed-system package list not found: $package_list" >&2
    exit 1
fi

mapfile -t packages < <(
    grep -Ev '^[[:space:]]*(#|$)' "$package_list"
)

if (( ${#packages[@]} == 0 )); then
    echo "No additional installed-system packages specified."
    exit 0
fi

echo "Installing Archforge default packages: ${packages[*]}"

/usr/bin/pacstrap \
    -C /etc/calamares/target-pacman.conf \
    "$target" \
    "${packages[@]}"
