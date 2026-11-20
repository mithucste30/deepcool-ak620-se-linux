#!/usr/bin/env bash
# Convenience installer: builds the .deb and installs it WITH all
# dependencies resolved (python3-gi, GTK3 and Ayatana appindicator girs).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
"$HERE/build-deb.sh"
DEB="$(ls -1 "$HERE"/dist/deepcool-digital-linux_*_amd64.deb | sort -V | tail -1)"
echo ">> installing $DEB (dependencies resolved via apt)"
sudo apt install -y "$DEB"
echo ">> installed. Launch 'DeepCool Digital' from the app grid or tray."
