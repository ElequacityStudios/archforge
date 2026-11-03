#!/usr/bin/bash
set -euo pipefail

echo "Archforge: removing non-English translations..."
if [[ -d /usr/share/locale ]]; then
    find /usr/share/locale -mindepth 1 -maxdepth 1 -type d ! -name "en*" -exec rm -rf -- {} +
fi

echo "Archforge: removing documentation and man pages..."
rm -rf /usr/share/doc/*
rm -rf /usr/share/man/*

echo "Archforge: live filesystem cleanup complete."
