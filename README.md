# mpv Custom OSC — Minimal GUI

A custom On-Screen Controller for [mpv](https://mpv.io/) that replaces the default OSC with a modern, minimal interface.

## Features

- **Progress bar** with smooth drag-to-seek and circular handle
- **Play/Pause** button (centered)
- **Time display** (current / total)
- **Subtitle selector** (CC button with dropdown menu)
- **Drop zone** when no file is loaded
- **Auto-hide** after 2 seconds of inactivity
- **Gradient background** with eased transparency

## Installation

### Windows
Copy the contents of this folder to your mpv config directory:
```
%APPDATA%\mpv\
```

### Linux / macOS
Copy the contents to:
```
~/.config/mpv/
```

### Required setting
Make sure `mpv.conf` contains:
```
osc=no
```
This disables the default OSC so the custom one can take over.

## File Structure

```
mpv/
├── mpv.conf              # mpv config (osc=no)
├── input.conf            # Key bindings (optional)
├── fonts.conf            # Font configuration
├── test_gui.bat          # Test script (Windows)
├── script-opts/
│   └── custom_osc.conf   # User settings (overrides defaults)
└── scripts/
    └── gui/
        ├── main.lua          # Entry point, event loop
        ├── config.lua        # Default options + mp.options loader
        ├── state.lua         # Shared state between components
        └── elements/
            ├── Element.lua       # Base class
            ├── Background.lua    # Gradient background
            ├── ProgressBar.lua   # Seekbar with handle
            ├── PlayButton.lua    # Play/Pause toggle
            ├── SkipButtons.lua   # ±5s seek buttons
            ├── VolumeButton.lua  # Volume + mute control
            ├── TimeDisplay.lua   # Time counter
            ├── Subs.lua          # Subtitle selector
            └── DropZone.lua      # Empty state UI
```

## Customization

Edit `script-opts/custom_osc.conf` to override any default setting **without touching the code**.

Example — change the progress bar color to blue and disable mouse wheel volume:
```
color_played=FF0000
mouse_wheel_volume=no
```

### Available Options

| Option | Default | Description |
|--------|---------|-------------|
| `color_played` | `0000FF` | Progress bar color (BGR hex) |
| `bar_height` | `3` | Bar thickness (px) |
| `bar_hover_height` | `5` | Bar thickness on hover (px) |
| `handle_size` | `14` | Seek handle diameter (px) |
| `box_height` | `70` | Total control area height (px) |
| `font_size` | `14` | Time display font size |
| `mouse_wheel_volume` | `yes` | Mouse wheel controls volume |
| `volume_step` | `5` | Volume change per wheel tick |
| `seek_step` | `5` | Seconds to skip with ◀◀/▶▶ |
| `auto_hide_timeout` | `2` | Seconds before UI auto-hides |

## Testing

Run the test script to launch mpv with a sample video:
```
test_gui.bat
```
This downloads a short clip and opens it with the custom GUI.

## License

Personal project — feel free to fork and modify.
