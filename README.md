# Noctalia Plugins

A collection of plugins for [Noctalia](https://noctalia.dev) **v5** (Luau plugin API).

## Installation

In Noctalia, add this repository as a plugin source, then enable the plugin
from Settings > Plugins. The repo-root `catalog.toml` lists what it ships.

To develop locally, point a path source at this repo (or a plugin subdir) instead.

## Available Plugins

| Plugin | Description |
|--------|-------------|
| [globalprotect-vpn](globalprotect-vpn) | GlobalProtect VPN connection toggle with status indicator |

## Development

Noctalia v5 plugins are [Luau](https://luau.org) scripts driven by a `plugin.toml`
manifest. Bar widgets paint via the `barWidget.*` API and react through
`update()` / `onClick()` / `onRightClick()` / `onMiddleClick()` / `onHover()`
callbacks; host services (run commands, notify, env, persistent state) live under
`noctalia.*`.

### Repository layout

```
catalog.toml                     # lists plugins shipped by this source (required)
<plugin-name>/
├── plugin.toml                  # plugin manifest + settings schema (required)
├── main.luau                    # widget entry script (referenced by `entry`)
└── README.md                    # plugin documentation (optional)
```

A plugin id is `author/plugin`; by convention the plugin lives in the `plugin`
subdirectory (e.g. id `nappairam/globalprotect-vpn` → `globalprotect-vpn/`).

### Creating a new plugin

1. Create a directory at the repo root named after the plugin segment of its id.
2. Add a `plugin.toml` with `id`, `name`, `min_noctalia`, and at least one entry
   (e.g. `[[widget]]`) plus any `[[widget.setting]]` fields.
3. Implement the entry Luau script referenced by `entry`.
4. Add a `[[plugin]]` row to the repo-root `catalog.toml`.
5. Test via a path plugin source pointing at the repo.

## License

MIT
