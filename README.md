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
├── mpv.conf          # mpv config (osc=no)
├── input.conf        # Key bindings (optional)
├── fonts.conf        # Font configuration
├── test_gui.bat      # Test script (Windows)
└── scripts/
    └── gui/
        ├── main.lua          # Entry point, event loop
        ├── config.lua        # Visual configuration (colors, sizes, margins)
        ├── state.lua         # Shared state between components
        └── elements/
            ├── Element.lua       # Base class
            ├── Background.lua    # Gradient background
            ├── ProgressBar.lua   # Seekbar with handle
            ├── PlayButton.lua    # Play/Pause toggle
            ├── TimeDisplay.lua   # Time counter
            ├── Subs.lua          # Subtitle selector
            └── DropZone.lua      # Empty state UI
```

## Customization

Edit `scripts/gui/config.lua` to customize:
- `color_played` — Progress bar color (BGR format)
- `bar_height` / `bar_hover_height` — Bar thickness
- `handle_size` — Seek handle diameter
- `box_height` — Total control area height
- `font_size` — Time display font size

## Testing

Run the test script to launch mpv with a sample video:
```
test_gui.bat
```
This downloads a short clip and opens it with the custom GUI.

## License

Personal project — feel free to fork and modify.
