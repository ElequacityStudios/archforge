<p align="left">
  <img src="assets/branding/archforge.png" alt="Archforge Logo" width="180">
</p>

# Archforge
An Arch based linux distribution focused on bringing a more open OS to PCs and handheld devices.

Archforge aims to provide a polished, user-friendly Arch Linux experience with some extra goodies like the Steam Deck UI in the Gaming edition. 

## Features

- **Arch Linux base** — An open, rolling-release system with access to the latest packages.
- **KDE Plasma live ISO** — A familiar desktop experience with an easy to use graphical installer.
- **Desktop choices** — Choose between KDE Plasma and GNOME during installation.
- **Graphics driver selection** — Choose automatic hardware detection or manually select graphics drivers.
- **Steam preinstalled** — Steam is included by default, with the required 32-bit libraries.
- **AUR support** — Paru is installed as the default AUR helper.
- **Multilib enabled** — Support for 32-bit applications and gaming libraries.
- **Fast Mirrors** — Reflector periodically optimizes pacman mirror selection leading to faster package downloads.
- **GRUB bootloader** — A standard and stable bootloader.

## Downloads
Download the latest available release from the [GitHub Releases](../../releases) page.
Each release includes the installation ISO and a SHA-256 checksum file for verification.

## Installation
1. Download an ISO from the Releases page.
2. Flash the ISO onto a USB drive using a tool such as Rufus, balenaEtcher, or `dd`.
3. Boot into the flashed USB drive.
4. Launch the installer from the desktop or explore KDE Plasma.
5. Follow the installation instructions.

**WARNING:** Be careful when partitioning drives. Modifying drives could lead to **data loss**.

## Building from source
Archforge uses [Archiso](https://wiki.archlinux.org/title/Archiso) to build its installation images.

On an Arch Linux system, install the required tools:

```bash
sudo pacman -S --needed archiso git
```


Clone the repository:
```bash
git clone https://github.com/ElequacityStudios/archforge.git
cd archforge
```


Build the Desktop Edition:
```bash
sudo mkarchiso -v \
    -w /var/tmp/archforge-work \
    -o out \
    profile
```


Or build the Gaming Edition:
```bash
sudo mkarchiso -v \
    -w /var/tmp/archforge-work \
    -o out \
    profile-gaming
```

The resulting ISO will be placed in the `out/` directory.

## Contributing
Contributions, bug reports, and suggestions are welcome.

- Report bugs and suggest stuff through [GitHub Issues](../../issues).
- Submit changes through Pull Requests.

## Project status
Archforge is an actively developed project. The Desktop Edition is still in its early stages, and the Gaming Edition is probably being worked on right now.
Features, installation procedures, and system configurations may change between releases.

## License
Archforge is licensed under the **GNU General Public License v3.0 or later**.

See [LICENSE](LICENSE) for details.

## Acknowledgements
Archforge builds upon the work of the Arch Linux community and the developers of the open-source software included in the distribution.
Many thanks to the developers and maintainers of Archiso, Calamares, KDE Plasma, GNOME, Steam, and the many other projects that make projects like this possible.
