#!/usr/bin/env bash
# Build an .rpm package for deepcool-digital-linux (DeepCool AK620 DIGITAL display driver)
# Requires: rpmbuild  (on Debian/Pop/Ubuntu: sudo apt install rpm)
# Usage: ./build-rpm.sh   (optionally: VER=0.11.0 ./build-rpm.sh)
set -euo pipefail

VER="${VER:-0.11.0}"
REL="${REL:-9}"
# upstream release tag (can differ from the numeric VER, e.g. "-alpha")
UPSTREAM_TAG="${UPSTREAM_TAG:-v0.11.0-alpha}"
SHA256="9365c604831738a5a30128084b7821e01cea16c96ca2f5cbed51b9c0336dabce"
URL="https://github.com/Nortank12/deepcool-digital-linux/releases/download/${UPSTREAM_TAG}/deepcool-digital-linux"
HERE="$(cd "$(dirname "$0")" && pwd)"
STAGING="$HERE/staging"
TOPDIR="$HERE/pkg-rpm"
DIST="$HERE/dist"

command -v rpmbuild >/dev/null || { echo "ERROR: rpmbuild not found. Install with: sudo apt install rpm"; exit 1; }

mkdir -p "$STAGING" "$DIST"

# 1. Fetch the upstream binary if missing or if the checksum doesn't match
BIN="$STAGING/deepcool-digital-linux"
if [ ! -x "$BIN" ] || ! echo "$SHA256  $BIN" | sha256sum -c --quiet; then
    echo ">> downloading deepcool-digital-linux v${VER} ..."
    curl -fSL --retry 3 -o "$BIN" "$URL"
    chmod +x "$BIN"
    echo "$SHA256  $BIN" | sha256sum -c -
fi

# 2. rpmbuild tree + SOURCES payload
rm -rf "$TOPDIR"
for d in BUILD RPMS SRPMS SOURCES SPECS; do mkdir -p "$TOPDIR/$d"; done
SRC="$TOPDIR/SOURCES/deepcool-digital-linux-${VER}"
install -d "$SRC"
install -m 0755 "$BIN"                                     "$SRC/deepcool-digital-linux"
install -m 0644 "$HERE/assets/deepcool-digital.service"    "$SRC/deepcool-digital.service"
install -m 0755 "$HERE/assets/bin/deepcool-digital-gui"    "$SRC/deepcool-digital-gui"
install -m 0755 "$HERE/assets/bin/deepcool-digital-smart"  "$SRC/deepcool-digital-smart"
install -m 0644 "$HERE/assets/deepcool-digital-user.service" "$SRC/deepcool-digital-user.service"
install -m 0644 "$HERE/assets/deepcool-digital-smart.service" "$SRC/deepcool-digital-smart.service"
install -m 0644 "$HERE/assets/deepcool-digital-gui.desktop" "$SRC/deepcool-digital-gui.desktop"
install -m 0644 "$HERE/assets/deepcool-digital-gui-autostart.desktop" "$SRC/deepcool-digital-gui-autostart.desktop"
install -m 0644 "$HERE/assets/deepcool-digital.svg" "$SRC/deepcool-digital.svg"
install -d "$SRC/icons"
for dir in "$HERE"/assets/icons/*x*; do
    size="$(basename "$dir")"
    install -D -m 0644 "$dir/deepcool-digital.png" "$SRC/icons/$size/deepcool-digital.png"
done
install -m 0644 "$HERE/assets/org.deepcool.digital.gui.metainfo.xml" "$SRC/org.deepcool.digital.gui.metainfo.xml"
install -m 0644 "$HERE/assets/99-deepcool-digital.rules"   "$SRC/99-deepcool-digital.rules"
tar -C "$TOPDIR/SOURCES" -czf "$TOPDIR/SOURCES/deepcool-digital-linux-${VER}.tar.gz" "deepcool-digital-linux-${VER}"

# 3. Spec file
cat > "$TOPDIR/SPECS/deepcool-digital-linux.spec" <<EOF
# prebuilt upstream binary: no sources, no debuginfo package
%define debug_package %{nil}
Name:    deepcool-digital-linux
Version: ${VER}
Release: ${REL}%{?dist}
Summary: DeepCool DIGITAL cooler display driver for Linux
License: GPL-3.0-or-later
URL:     https://github.com/Nortank12/deepcool-digital-linux
Source0: %{name}-%{version}.tar.gz
BuildArch: x86_64
Requires: systemd
Requires: python3-gobject
Requires: gtk3
Requires: libayatana-appindicator-gtk3

# Macro fallbacks so this builds with plain rpmbuild (e.g. Debian's rpm package)
%if %{undefined _unitdir}
%global _unitdir /usr/lib/systemd/system
%endif
%if %{undefined _udevrulesdir}
%global _udevrulesdir /usr/lib/udev/rules.d
%endif
%if %{undefined _userunitdir}
%global _userunitdir /usr/lib/systemd/user
%endif

%description
Drives the digital display on DeepCool DIGITAL coolers (e.g. AK620
DIGITAL / DIGITAL SE) showing CPU temperature and usage, replicating
the DeepCool Digital Windows software. Runs as a systemd service;
udev rule allows rootless CLI access.

%prep
%setup -q

%build
# prebuilt upstream release binary; nothing to compile

%install
install -D -m 0755 deepcool-digital-linux %{buildroot}/%{_bindir}/deepcool-digital-linux
install -D -m 0755 deepcool-digital-gui %{buildroot}/%{_bindir}/deepcool-digital-gui
install -D -m 0755 deepcool-digital-smart %{buildroot}/%{_bindir}/deepcool-digital-smart
install -D -m 0644 deepcool-digital.service %{buildroot}/%{_unitdir}/deepcool-digital.service
install -D -m 0644 deepcool-digital-user.service %{buildroot}/%{_userunitdir}/deepcool-digital.service
install -D -m 0644 deepcool-digital-smart.service %{buildroot}/%{_userunitdir}/deepcool-digital-smart.service
install -D -m 0644 deepcool-digital-gui.desktop %{buildroot}/%{_datadir}/applications/deepcool-digital-gui.desktop
install -D -m 0644 deepcool-digital-gui-autostart.desktop %{buildroot}/%{_sysconfdir}/xdg/autostart/deepcool-digital-gui.desktop
install -D -m 0644 deepcool-digital.svg %{buildroot}/%{_datadir}/icons/hicolor/scalable/apps/deepcool-digital.svg
for dir in icons/*x*; do
    size="$(basename "$dir")"
    install -D -m 0644 "$dir/deepcool-digital.png" "%{buildroot}/%{_datadir}/icons/hicolor/$size/apps/deepcool-digital.png"
done
install -D -m 0644 org.deepcool.digital.gui.metainfo.xml %{buildroot}/%{_datadir}/metainfo/org.deepcool.digital.gui.metainfo.xml
install -D -m 0644 99-deepcool-digital.rules %{buildroot}/%{_udevrulesdir}/99-deepcool-digital.rules

%post
systemctl daemon-reload >/dev/null 2>&1 || :
# when a user session already owns the display, don't start a competing service
if ! ls /home/*/.config/systemd/user/default.target.wants/deepcool-digital.service >/dev/null 2>&1; then
    systemctl enable --now deepcool-digital.service >/dev/null 2>&1 || :
fi
udevadm control --reload-rules || :
udevadm trigger --subsystem-match=hidraw || :

%preun
if [ "\$1" = "0" ]; then
    systemctl disable --now deepcool-digital.service >/dev/null 2>&1 || :
fi

%files
%{_bindir}/deepcool-digital-linux
%{_bindir}/deepcool-digital-gui
%{_bindir}/deepcool-digital-smart
%{_unitdir}/deepcool-digital.service
%{_userunitdir}/deepcool-digital.service
%{_userunitdir}/deepcool-digital-smart.service
%{_datadir}/applications/deepcool-digital-gui.desktop
%{_sysconfdir}/xdg/autostart/deepcool-digital-gui.desktop
%{_datadir}/icons/hicolor/scalable/apps/deepcool-digital.svg
%{_datadir}/icons/hicolor/*/apps/deepcool-digital.png
%{_datadir}/metainfo/org.deepcool.digital.gui.metainfo.xml
%{_udevrulesdir}/99-deepcool-digital.rules
EOF

# 4. Build
rpmbuild -bb --define "_topdir $TOPDIR" "$TOPDIR/SPECS/deepcool-digital-linux.spec"
cp "$TOPDIR"/RPMS/x86_64/*.rpm "$DIST/"
echo ">> built $(ls "$DIST"/deepcool-digital-linux-*${VER}*.rpm)"
