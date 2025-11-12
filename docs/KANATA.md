# Kanata macOS Setup Instructions

**Source:** [jtroo/kanata#1264](https://github.com/jtroo/kanata/issues/1264#issuecomment-2763085239)

---

## Setup Steps

### 1. Remove Standalone VirtualHIDDevice Driver

If you installed it, deactivate:

```bash
sudo /Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager deactivate
```

Reboot to be safe.

### 2. Install Full Karabiner Elements

Download and install `Karabiner-Elements-15.7.0.dmg`.

Follow all prompts to enable in System Settings:

**Login Items & Extensions:**
- Enable: Karabiner-Elements Non-Privileged Agents
- Enable: Karabiner-Elements Privileged Daemons
- Enable: Driver Extensions > .Karabiner-VirtualHIDDevice-Manager

**Privacy & Security > Input Monitoring:**
- Enable: iTerm
- Enable: karabiner_grabber
- Enable: Karabiner-Elements
- Enable: Karabiner-EventViewer
- Enable: Terminal

### 3. Quit Karabiner Completely

**Important:** Quit both:
1. The Karabiner app
2. The Karabiner icon in the macOS menu bar

If you don't, Kanata will complain something else is using the keyboard.

### 4. Reboot

Reboot again.

### 5. Run Kanata

```bash
sudo kanata --cfg your-config.kbd
```

---

## Notes

- Works with `cargo install kanata` and official releases from GitHub
- Don't use the standalone VirtualHIDDevice Driver from kanata README
- Use full Karabiner Elements instead, then quit it before running kanata
