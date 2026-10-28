# Prometheus Screenshot

A Prometheus-themed screenshot overlay for Hyprland, built with Quickshell.

A compact, frosted toolbar switches between **Drag**, **Window**, and **Full screen** capture. The desktop freezes before the overlay opens, so captures never include the controls. Every capture is copied to the clipboard, with optional disk saving.

Status: source install, tested on an Arch/CachyOS-style Hyprland session with Quickshell 0.3.2 and fractional scaling. Nix packaging is included but has not been built locally.

## Dependencies

- Quickshell 0.3.2 with QtQuick.Effects
- Hyprland (`hyprctl`)
- Python 3
- grim
- ImageMagick (`magick`)
- wl-clipboard (`wl-copy`)
- libnotify (`notify-send`)
- JetBrainsMono Nerd Font for the Prometheus typography

## Install

```bash
mkdir -p "$HOME/Projects"
git clone https://github.com/thanosipsis/prometheus-screenshot.git "$HOME/Projects/prometheus-screenshot"
cd "$HOME/Projects/prometheus-screenshot"
mkdir -p "$HOME/.local/bin"
ln -s "$PWD/launch.py" "$HOME/.local/bin/prometheus-screenshot"
```

Keep the checkout in place; the launcher resolves the project assets from it. Ensure `~/.local/bin` is on your PATH, then run:

```bash
prometheus-screenshot
```

Or run directly from the checkout:

```bash
python3 launch.py
```

Always start through the launcher so the desktop is captured before the UI opens.

## Controls

| Control | Shortcut | Behavior |
| --- | --- | --- |
| Drag | 1 | Drag a rectangle and release to capture |
| Window | 2 | Hover to highlight; click or press Enter to capture |
| Full screen | 3 | Select the mode, then click Capture or press Enter |
| Save | S | Toggle disk saving; clipboard copy is always enabled |
| Cancel | Escape | Close without capturing |

The overlay covers the display focused when launched. To capture another display, focus it and launch again. Window captures include only the visible portion on that display; obscured content is not reconstructed. Selections spanning multiple displays are not supported.

## Hyprland binding

Lua configuration:

```lua
hl.bind("Print", hl.dsp.exec_cmd("prometheus-screenshot"))
```

Hyprlang configuration:

```hypr
bind = , Print, exec, prometheus-screenshot
```

## Configuration

The default save folder is `~/Pictures/Screenshots`, created automatically. Set `PROMETHEUS_SCREENSHOT_DIR` to override it; `HQS_DIR` is supported as a compatibility fallback.

```bash
PROMETHEUS_SCREENSHOT_DIR="$HOME/Pictures/Captures" prometheus-screenshot
```

The Save preference persists in `capture.ini` under this shell's Quickshell state directory. Colors and fonts live in `theme/Theme.qml`.

The launcher uses private temporary directories and prevents duplicate overlays. Crops account for fractional display scaling. Clipboard ownership is established after Quickshell exits so the copied image remains available.

## Attribution

Based on [JamDon2/hyprquickshot](https://github.com/JamDon2/hyprquickshot), customized for the Prometheus desktop. Distributed under the [MIT license](LICENSE.md).
