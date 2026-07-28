# Kanata macOS Setup & Troubleshooting

Kanata needs the Karabiner DriverKit VirtualHIDDevice driver — and only a specific
major version of it. Both pieces are managed by this repo:

- `home/.chezmoiexternal.toml` — pins the kanata binary (`.local/bin/kanata`)
- `home/.chezmoiscripts/darwin/run_onchange_after_install-karabiner-vhid-driver.sh.tmpl`
  — installs the standalone driver at the version kanata expects

Karabiner-Elements is deliberately **not** installed: it was dropped from the cask
list and added to `$cleanup_list` in `run_onchange_install-packages.sh.tmpl`. Its
16.x releases bundle driver v8, which kanata cannot talk to.

---

## Driver version compatibility

| kanata | required driver |
| --- | --- |
| 1.10 – 1.12 | `v6.2.0` |

Currently pinned: kanata `1.12.0`, driver `6.2.0`.

Every kanata release names its driver in the release notes ("The supported Karabiner
driver version in this release is ..."). When bumping the kanata pin in
`.chezmoiexternal.toml`, check the notes and bump `DRIVER_VERSION` (plus
`DRIVER_SHA256`) in the driver script to match — `run_onchange` reinstalls on the next
`chezmoi apply`.

Check what is installed:

```bash
defaults read "/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/Info.plist" CFBundleVersion
systemextensionsctl list | grep -i virtualhid
```

`systemextensionsctl` reports the dext *bundle* version, which does not follow the
driver's release tags — use the daemon `CFBundleVersion` when comparing versions.

---

## Setup

1. `chezmoi apply` — downloads the kanata binary and installs the pinned driver
   (prompts for sudo, deactivates any other driver version first).
2. Approve the driver extension: **System Settings > General > Login Items &
   Extensions > Driver Extensions** > enable `.Karabiner-VirtualHIDDevice-Manager`.
3. Grant **Privacy & Security > Input Monitoring** to the terminal (Alacritty,
   Ghostty, iTerm) and to `kanata`.
4. Run `kanata` — zsh function in
   `home/exact_dot_my_zsh_plugins/functions/kanata.sh`, runs under sudo from
   `~/.config/kanata`.

Escape hatch while kanata runs: `lctl+spc+esc` (in `defsrc` terms, i.e. pre-remap).

---

## Troubleshooting

### `connect_failed asio.system:2` repeating forever

`asio.system:2` is `ENOENT`: kanata cannot find the daemon socket under
`/Library/Application Support/org.pqrs/tmp/rootonly/vhidd_server/`.

- A few lines at startup followed by normal operation is just kanata retrying while
  the daemon comes up — harmless.
- Endless repetition means **driver version mismatch** (e.g. v8 installed while
  kanata wants v6) or a dead daemon. Compare versions as above, then restart the
  daemon:

```bash
sudo launchctl kickstart -k system/org.pqrs.service.daemon.Karabiner-VirtualHIDDevice-Daemon
```

Upgrading kanata does not fix a mismatch — downgrade the driver instead.

### `Karabiner-VirtualHIDDevice driver is not activated`

The extension was never approved, or an install invalidated it. Re-activate:

```bash
sudo /Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager activate
```

Approve it in System Settings, and reboot if it stays inactive.

### Something else is grabbing the keyboard

If Karabiner-Elements gets reinstalled, its `karabiner_grabber` fights kanata for the
device. Quit both the app and its menu bar icon, or better, uninstall it
(`brew uninstall karabiner-elements`) and let the driver script own the driver.

### Remaps silently stop working

Reset Input Monitoring: remove the terminal and `kanata` from **Input Monitoring**,
re-add them, restart the terminal, rerun kanata.

---

For the layer and alias reference, see [KANATA.md](./KANATA.md).
