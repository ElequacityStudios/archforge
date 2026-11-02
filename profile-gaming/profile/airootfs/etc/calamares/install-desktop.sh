#!/usr/bin/bash
set -euo pipefail
desktop="${1:?Missing desktop selection}"
root="${2:?Missing installation root}"
config="/etc/calamares/target-pacman.conf"

case "$desktop" in
  kde)
    /usr/bin/pacstrap -C "$config" -K "$root" plasma-meta plasma-workspace-wallpapers plasma-login-manager plasma-setup-git dolphin konsole xdg-desktop-portal-kde
    /usr/bin/systemd-sysusers --root="$root"
    /usr/bin/systemctl --root="$root" enable plasmalogin.service plasma-setup.service
    ;;
  gnome)
    /usr/bin/pacstrap -C "$config" -K "$root" gnome-shell gnome-session gnome-control-center gnome-settings-daemon gnome-terminal nautilus gdm gnome-initial-setup gnome-backgrounds gnome-keyring gnome-disk-utility gnome-calculator gnome-system-monitor gnome-text-editor evince loupe file-roller gnome-software xdg-desktop-portal-gnome
    /usr/bin/systemd-sysusers --root="$root"
    /usr/bin/systemctl --root="$root" enable gdm.service
    ;;
  *)
    echo "Invalid desktop selection: $desktop" >&2
    exit 1
    ;;
esac
