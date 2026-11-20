# deepcool-digital-linux — local packaging

Packages [Nortank12/deepcool-digital-linux](https://github.com/Nortank12/deepcool-digital-linux)
(v0.11.0, sha256-pinned) so the **DeepCool AK620 DIGITAL (SE)** cooler display works on Linux:
CPU temperature + usage, like the Windows "DeepCool Digital" app.

## Contents

| Path | Purpose |
|---|---|
| `install.sh` | Build + install the .deb with **all dependencies resolved** (one command) |
| `.github/workflows/ci.yml` | CI: builds both packages on push; **tag `v*` → GitHub Release** with .deb + .rpm attached |
| `build-deb.sh` | Build `dist/deepcool-digital-linux_<ver>_amd64.deb` |
| `build-rpm.sh` | Build `dist/deepcool-digital-linux-<ver>.x86_64.rpm` (needs `rpmbuild`, on Debian-family: `apt install rpm`) |
| `assets/bin/deepcool-digital-gui` | GTK3 + Ayatana **tray app** to toggle display mode (`/usr/bin/`, app grid entry "DeepCool Digital") |
| `assets/bin/deepcool-digital-smart` | mode manager: Smart (load-aware) + Auto (alternates temp/usage with **instant** transitions — writes display packets directly to the hidraw device; restarting the driver per flip would re-init the screen) |
| `assets/deepcool-digital.service` | system-level systemd unit (headless use, `/lib/systemd/system/`) |
| `assets/deepcool-digital-user.service` | user-level systemd unit driven by the GUI (`/lib/systemd/user/`, config `~/.config/deepcool-digital.conf`) |
| `assets/deepcool-digital-smart.service` | user-level unit for the Smart watcher |
| `assets/deepcool-digital-gui.desktop` | app-grid launcher |
| `assets/deepcool-digital-gui-autostart.desktop` | starts the tray app at login (`/etc/xdg/autostart/`) |
| `assets/deepcool-digital.svg` | app/tray icon (hicolor scalable) |
| `assets/99-deepcool-digital.rules` | udev rule: hidraw VID `3633` for rootless CLI use |

Each build script downloads the pinned upstream binary, verifies its sha256, and assembles the package.
Re-run any time; pass `VER=x.y.z` to package a newer release (update the sha256 in the script).

## Install

Prebuilt packages are on the [Releases](../../releases) page (built by CI).

```bash
# Debian/Ubuntu/Pop — one command, pulls python3-gi + GTK3 + Ayatana indicator:
./install.sh
# or from a released .deb (apt resolves the dependencies):
sudo apt install ./deepcool-digital-linux_*_amd64.deb
# Fedora/RHEL/openSUSE:
sudo dnf install ./deepcool-digital-linux-*.rpm
```

The package enables + starts the system-level `deepcool-digital.service` (multi-user target, restarts on failure).
The display shows CPU temp by default; the SE layout also shows usage.

## Releases (CI/CD)

`.github/workflows/ci.yml` builds both packages on every push/PR. To cut a release:

```bash
# bump VER/REL defaults in build-*.sh (and the sha256 when bumping VER), then:
git tag v0.11.0-3 && git push origin v0.11.0-3   # tag = VER-REL
```

The tag pipeline builds the .deb + .rpm and publishes a GitHub Release with both attached.

## GUI + system tray

Launch **"DeepCool Digital"** from the app grid (or `/usr/bin/deepcool-digital-gui`).
It lives in the **system tray**: closing the window keeps it running in the
background; left-click the tray icon to reopen; right-click for quick mode
switching and Quit. It autostarts at login via `/etc/xdg/autostart`.
Toggles apply instantly, no root:

- Display mode: **Temperature / CPU usage / Auto / Smart** (load-aware)
- Fahrenheit, temperature alarm, update interval (250–2000 ms)
- **Start at login** toggle (XDG autostart override in `~/.config/autostart/`)

On first run the GUI moves display ownership from the system service to a
**user** service (`systemctl --user`), which reads `DEEPCOOL_ARGS` from
`~/.config/deepcool-digital.conf` — the GUI just rewrites that file and
restarts the unit. The display keeps running when the GUI is closed.
Only one of the two services may run at a time; the GUI detects the conflict
and offers a one-click takeover.

## Display modes (AK series)

Change by editing the service command, e.g. a drop-in:

```bash
sudo systemctl edit deepcool-digital
#   [Service]
#   ExecStart=
#   ExecStart=/usr/bin/deepcool-digital-linux -m auto     # alternate temp <-> usage
#   # other AK-valid modes: cpu_temp (default), cpu_usage
#   # extras: -f (Fahrenheit), -a (alarm), -u 500 (faster updates)
sudo systemctl restart deepcool-digital
```

Manual test without the service (udev rule allows user access):

```bash
deepcool-digital-linux --list          # e.g. "2 | AK620-DIGITAL"
deepcool-digital-linux -m cpu_usage    # Ctrl+C to stop
```

## Uninstall

```bash
sudo apt remove deepcool-digital-linux     # or: sudo dnf remove deepcool-digital-linux
```
