# deepcool-digital-linux — local packaging

Packages [Nortank12/deepcool-digital-linux](https://github.com/Nortank12/deepcool-digital-linux)
(v0.11.0, sha256-pinned) so the **DeepCool AK620 DIGITAL (SE)** cooler display works on Linux:
CPU temperature + usage, like the Windows "DeepCool Digital" app.

## Contents

| Path | Purpose |
|---|---|
| `build-deb.sh` | Build `dist/deepcool-digital-linux_0.11.0_amd64.deb` |
| `build-rpm.sh` | Build `dist/deepcool-digital-linux-0.11.0-1*.x86_64.rpm` (needs `rpmbuild`, on Debian-family: `apt install rpm`) |
| `assets/bin/deepcool-digital-gui` | GTK4 GUI to toggle display mode (installed to `/usr/bin/`, app grid entry "DeepCool Digital") |
| `assets/deepcool-digital.service` | system-level systemd unit (headless use, installed to `/lib/systemd/system/`) |
| `assets/deepcool-digital-user.service` | user-level systemd unit driven by the GUI (`/lib/systemd/user/`, config `~/.config/deepcool-digital.conf`) |
| `assets/deepcool-digital-gui.desktop` | app-grid launcher for the GUI |
| `assets/99-deepcool-digital.rules` | udev rule: hidraw VID `3633` for rootless CLI use |

Each script downloads the pinned upstream binary, verifies its sha256, and assembles the package.
Re-run any time; pass `VER=x.y.z` to package a newer release (update the sha256 in the script).

## Install

```bash
./build-deb.sh
sudo apt install ./dist/deepcool-digital-linux_0.11.0_amd64.deb   # Debian/Ubuntu/Pop
# or on Fedora/RHEL/openSUSE:
./build-rpm.sh && sudo dnf install ./dist/deepcool-digital-linux-*.rpm
```

The package enables + starts the system-level `deepcool-digital.service` (multi-user target, restarts on failure).
The display shows CPU temp by default; the SE layout also shows usage.

## GUI (Windows-app style)

Launch **"DeepCool Digital"** from the app grid (or `/usr/bin/deepcool-digital-gui`). Toggles apply instantly, no root:

- Display mode: **Temperature / CPU usage / Auto** (alternates both)
- Fahrenheit, temperature alarm, update interval (250–2000 ms)

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
