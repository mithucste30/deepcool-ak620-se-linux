#!/usr/bin/env bash
# Build a .deb package for deepcool-digital-linux (DeepCool AK620 DIGITAL display driver)
# Usage: ./build-deb.sh   (optionally: VER=0.11.0 ./build-deb.sh)
set -euo pipefail

VER="${VER:-0.11.0}"
REL="${REL:-2}"
SHA256="9365c604831738a5a30128084b7821e01cea16c96ca2f5cbed51b9c0336dabce"
URL="https://github.com/Nortank12/deepcool-digital-linux/releases/download/v${VER}/deepcool-digital-linux"
HERE="$(cd "$(dirname "$0")" && pwd)"
STAGING="$HERE/staging"
PKG="$HERE/pkg-deb"
DIST="$HERE/dist"

mkdir -p "$STAGING" "$DIST"

# 1. Fetch the upstream binary if missing or if the checksum doesn't match
BIN="$STAGING/deepcool-digital-linux"
if [ ! -x "$BIN" ] || ! echo "$SHA256  $BIN" | sha256sum -c --quiet; then
    echo ">> downloading deepcool-digital-linux v${VER} ..."
    curl -fSL --retry 3 -o "$BIN" "$URL"
    chmod +x "$BIN"
    echo "$SHA256  $BIN" | sha256sum -c -
fi

# 2. Assemble the package filesystem tree
rm -rf "$PKG"
install -D -m 0755 "$BIN"                        "$PKG/usr/bin/deepcool-digital-linux"
install -D -m 0755 "$HERE/assets/bin/deepcool-digital-gui" "$PKG/usr/bin/deepcool-digital-gui"
install -D -m 0755 "$HERE/assets/bin/deepcool-digital-smart" "$PKG/usr/bin/deepcool-digital-smart"
install -D -m 0644 "$HERE/assets/deepcool-digital.service" "$PKG/lib/systemd/system/deepcool-digital.service"
install -D -m 0644 "$HERE/assets/deepcool-digital-user.service" "$PKG/lib/systemd/user/deepcool-digital.service"
install -D -m 0644 "$HERE/assets/deepcool-digital-smart.service" "$PKG/lib/systemd/user/deepcool-digital-smart.service"
install -D -m 0644 "$HERE/assets/deepcool-digital-gui.desktop" "$PKG/usr/share/applications/deepcool-digital-gui.desktop"
install -D -m 0644 "$HERE/assets/99-deepcool-digital.rules" "$PKG/lib/udev/rules.d/99-deepcool-digital.rules"

# 3. Debian control + maintainer scripts
install -d -m 0755 "$PKG/DEBIAN"
cat > "$PKG/DEBIAN/control" <<EOF
Package: deepcool-digital-linux
Version: ${VER}-${REL}
Section: admin
Priority: optional
Architecture: amd64
Depends: python3-gi, gir1.2-gtk-4.0
Maintainer: mithu <mithu@localhost>
Description: DeepCool DIGITAL cooler display driver for Linux
 Drives the digital display on DeepCool DIGITAL coolers (e.g. AK620
 DIGITAL / DIGITAL SE) showing CPU temperature and usage, replicating
 the DeepCool Digital Windows software.
 Runs as a systemd service; udev rule allows rootless CLI access.
 Homepage: https://github.com/Nortank12/deepcool-digital-linux
EOF

cat > "$PKG/DEBIAN/postinst" <<'EOF'
#!/bin/bash
set -e
if command -v udevadm >/dev/null 2>&1; then
    udevadm control --reload-rules || true
    udevadm trigger --subsystem-match=hidraw || true
fi
if command -v systemctl >/dev/null 2>&1; then
    systemctl daemon-reload || true
    systemctl enable --now deepcool-digital.service || true
fi
EOF

cat > "$PKG/DEBIAN/prerm" <<'EOF'
#!/bin/bash
set -e
if [ "$1" = "remove" ] && command -v systemctl >/dev/null 2>&1; then
    systemctl disable --now deepcool-digital.service || true
fi
EOF
chmod 0755 "$PKG/DEBIAN/postinst" "$PKG/DEBIAN/prerm"

# 4. Build
OUT="$DIST/deepcool-digital-linux_${VER}-${REL}_amd64.deb"
dpkg-deb --build --root-owner-group "$PKG" "$OUT"
echo ">> built $OUT"
