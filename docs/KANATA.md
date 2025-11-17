# Kanata Configuration Documentation

This document describes the Kanata keyboard configuration setup, including naming conventions, layer structure, and usage patterns.

## Table of Contents

- [Naming Conventions](#naming-conventions)
- [Layer Structure](#layer-structure)
- [Navigation Patterns](#navigation-patterns)
- [Access Methods](#access-methods)
- [Layer Purposes](#layer-purposes)

---

## Naming Conventions

### Layer Aliases

Layer aliases follow a consistent pattern based on their behavior:

#### While-Held Layers (`l_wh_*`)
Temporary layers that automatically return to the previous layer when released:
- `l_wh_sys` - System layer (media controls, brightness)
- `l_wh_win` - Window management layer
- `l_wh_app` - App switching layer

**Usage:** Accessed via tap-hold or tap-dance; automatically returns when key is released.

#### Switch Layers (`l_sw_*`)
Persistent layers that remain active until explicitly switched away:
- `l_sw_sys` - System layer (switch mode)
- `l_sw_win` - Window management layer (switch mode)
- `l_sw_app` - App switching layer (switch mode)

**Usage:** Accessed from actions layer; stays active until navigated away via ESC or backspace.

#### Primary Layers
- `l_qwe` - Qwerty layout
- `l_cmk` - Colemak layout
- `l_act` - Actions layer (hub for accessing other layers)
- `l_scr` - Screenshot layer
- `l_ray` - Raycast extensions layer
- `l_fn` - Function keys layer

### Action Aliases

Actions follow the `a_<category>_<action>` pattern:

#### Window Management (`a_win*`)
- `a_winmax` - Maximize window (full)
- `a_winamax` - Almost maximize window
- `a_winmovh/j/k/l` - Move window left/down/up/right (vim directions)
- `a_winmosw` - Move window to another monitor

#### Screenshot (`a_scr*`)
- `a_scrarea` - Capture area
- `a_scrfull` - Capture fullscreen

#### App Opening (`a_opn_*`)
- `a_opn_ala` - Open Alacritty
- `a_opn_agi` - Open ChatGPT/Claude
- `a_opn_arc` - Open Arc
- `a_opn_fan` - Open Fantastical
- `a_opn_mai` - Open Mail
- `a_opn_pst` - Open Postman
- `a_opn_slk` - Open Slack
- `a_opn_spo` - Open Spotify
- `a_opn_obd` - Open Obsidian
- `a_opn_tod` - Open Todoist
- `a_opn_tgr` - Open Telegram
- `a_opn_wts` - Open WhatsApp
- `a_opn_zoo` - Open Zoom

#### Raycast Actions (`a_*`)
- `a_cliphis` - Clipboard history
- `a_confett` - Confetti animation
- `a_emojlst` - Emoji list
- `a_snippet` - Snippets
- `a_locksys` - Lock system

### Layout-Specific Aliases

#### Grave Key Layer Switching
- `l_qwe_grv` - Tap for `` ` ``, hold to switch to Colemak
- `l_cmk_grv` - Tap for `` ` ``, hold to switch to Qwerty

---

## Layer Structure

### Base Layers

**Qwerty** (`qwerty`)
- Default English layout
- Access: Hold `` ` `` in Colemak

**Colemak** (`colemak`)
- Alternative layout
- Access: Hold `` ` `` in Qwerty

### Hub Layer

**Actions** (`actions`)
- Central navigation layer for accessing all sublayers
- Access: `df` chord (in Qwerty)

### Sublayers (Accessed from Actions)

**Screenshot** (`screenshot`)
- `s` key in actions layer
- Screenshots via CleanShot

**Raycast** (`raycast`)
- `r` key in actions layer
- Raycast extensions and utilities

**Window** (`window`)
- `w` key in actions layer
- Window management via Raycast

**App** (`app`)
- `o` key in actions layer
- Quick app launching

**System** (`system`)
- Available via `l_sw_sys` if added to actions
- Media controls and system functions

### Special Layers

**Fn** (`fn`)
- Function keys (F1-F12)
- Access: Hold `fn` key

---

## Navigation Patterns

All sublayers follow consistent navigation:

### ESC Key
**Function:** Quick exit to Qwerty
- Press ESC from any sublayer to immediately return to Qwerty layout
- Useful for emergency exits or when you want to return to base layer quickly

### Backspace Key
**Function:** Return to parent layer

From sublayers (screenshot, raycast, window, app, system):
- Returns to actions layer

From actions layer:
- Returns to Qwerty

### Visual Flow

```
Qwerty/Colemak
    ↓ (df chord)
Actions Layer
    ↓ (w/r/s/o)
Sublayers (window/raycast/screenshot/app)
    ↓ (backspace)
Back to Actions
    ↓ (backspace or ESC)
Back to Qwerty
```

---

## Access Methods

### Chord Access

**Actions Layer:** `df` chord
- Press `d` and `f` simultaneously in Qwerty
- Ignored in Colemak layout
- Timeout: `$chord-timeout-slow` (50ms)

**Raycast Actions (Direct):**
From anywhere using semicolon chords:
- `; + c` - Confetti
- `; + e` - Emoji list
- `; + t` - Snippets
- `; + v` - Clipboard history
- `; + q` - Lock system

### Tap-Hold Access

**System Layer:** Hold `5` key
- Tap: Types `5`
- Hold: Activates system layer (while-held)

**Window Layer:** Hold `w` key
- Tap: Types `w`
- Hold: Activates window layer (while-held)

**Fn Layer:** Hold `fn` key
- Tap: Acts as `fn`
- Hold: Activates fn layer (while-held)

### Tap-Dance Access

**App Layer:** Tap `rmet` (right meta/command)
- Single tap: Acts as right meta
- Double tap: Activates app layer (while-held)

### Layer Switching (Persistent)

From actions layer:
- `w` - Switch to window layer (persistent)
- `r` - Switch to raycast layer (persistent)
- `s` - Switch to screenshot layer (persistent)
- `o` - Switch to app layer (persistent)

---

## Layer Purposes

### Actions Layer
**Purpose:** Hub for accessing all other layers
**Keys:**
- `w` - Window management
- `r` - Raycast utilities
- `s` - Screenshots
- `o` - App launcher
- `ESC` - Exit to Qwerty
- `Backspace` - Exit to Qwerty

### Screenshot Layer
**Purpose:** Quick access to screenshot tools
**Keys:**
- `a` - Capture area
- `f` - Capture fullscreen
- `ESC` - Exit to Qwerty
- `Backspace` - Back to actions

### Raycast Layer
**Purpose:** Raycast extension shortcuts
**Keys:**
- `c` - Confetti
- `e` - Emoji list
- `t` - Snippets
- `v` - Clipboard history
- `ESC` - Exit to Qwerty
- `Backspace` - Back to actions

### Window Layer
**Purpose:** Window management with Raycast
**Keys:**
- `hjkl` - Move window (vim directions)
- `m` - Maximize
- `,` - Almost maximize
- `o` - Switch monitor
- `ESC` - Exit to Qwerty
- `Backspace` - Back to actions

### App Layer
**Purpose:** Quick app launching
**Keys:** Various letter keys mapped to apps (see naming conventions)
- `ESC` - Exit to Qwerty
- `Backspace` - Back to actions

### System Layer
**Purpose:** Media and system controls
**Keys:**
- Brightness controls (emoji icons)
- Volume controls (emoji icons)
- Media playback controls (emoji icons)
- `ESC` - Exit to Qwerty
- `Backspace` - Back to actions

### Fn Layer
**Purpose:** Function keys
**Keys:** F1-F12 mapped to main row
- `ESC` - Exit to Qwerty
- `Delete` - Mapped to backspace position

---

## Tips

1. **Learning the System:**
   - Start with the `df` chord to enter actions
   - Use ESC for quick exits
   - Use backspace to navigate back one level

2. **Multiple Access Methods:**
   - Temporary access: Use tap-hold (e.g., hold `w` for window layer)
   - Persistent access: Use actions layer (e.g., `df` then `w`)

3. **Semicolon Shortcuts:**
   - Common Raycast actions are available directly via `; + key`
   - No need to enter a layer for these

4. **Layout Switching:**
   - Hold `` ` `` to temporarily switch between Qwerty/Colemak
   - Useful for testing or specific key sequences

---

For setup and troubleshooting, see [KANATA_TROUBLESHOOTING.md](./KANATA_TROUBLESHOOTING.md).
