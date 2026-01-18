# Noctalia Plugins

A collection of plugins for [Noctalia](https://noctalia.dev).

## Installation

Copy the desired plugin folder to your Noctalia plugins directory:

```bash
cp -r plugins/<plugin-name> ~/.config/noctalia/plugins/
```

Then restart Noctalia and enable the plugin in Settings > Plugins.

## Available Plugins

| Plugin | Description |
|--------|-------------|
| *Coming soon* | |

## Development

See the [Noctalia Plugin Development Guide](https://docs.noctalia.dev/development/plugins/overview/) for documentation.

### Plugin Structure

Each plugin follows this structure:

```
plugin-name/
├── manifest.json              # Plugin metadata (required)
├── preview.png                # Preview image (optional)
├── Main.qml                   # Background logic (optional)
├── BarWidget.qml              # Bar widget component (optional)
├── DesktopWidget.qml          # Desktop widget (optional)
├── ControlCenterWidget.qml    # Control center button (optional)
├── LauncherProvider.qml       # Launcher search provider (optional)
├── Panel.qml                  # Panel overlay (optional)
├── Settings.qml               # Settings UI (optional)
└── README.md                  # Plugin documentation
```

### Creating a New Plugin

1. Create a new directory at the repo root with your plugin ID
2. Add a `manifest.json` with required fields
3. Implement at least one entry point (e.g., `BarWidget.qml`)
4. Test by symlinking to `~/.config/noctalia/plugins/`

## License

MIT
