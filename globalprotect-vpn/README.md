# GlobalProtect VPN

A Noctalia v5 bar widget that connects/disconnects a GlobalProtect VPN via
[`gpclient`](https://github.com/yuezk/GlobalProtect-openconnect) and shows the
tunnel status as a shield glyph.

- **Left click** - connect / disconnect
- **Right click** - cancel an in-flight connect

The shield is grey when disconnected, yellow while connecting, green when up.
Hover for details.

## Requirements

- `gpclient` on `PATH`
- Passwordless `sudo` for `gpclient` and (if using default-route) `ip route`,
  since the widget shells out via `sudo -E`.

## Settings

Configured in Settings > Plugins (declared in `plugin.toml`). Empty text fields
fall back to environment variables.

| Setting | Env fallback | Default | Purpose |
|---------|--------------|---------|---------|
| `portal` | `NOCTALIA_GPCLIENT_PORTAL` | _(empty)_ | Portal hostname; required |
| `gateway` | `NOCTALIA_GPCLIENT_GATEWAY` | _(empty)_ | Optional gateway override (`-g`) |
| `iface` | `NOCTALIA_GPCLIENT_INTERFACE` | `gpd0` | Tunnel interface name |
| `default_route` | - | `false` | Set `default dev <iface>` while connected |

When `default_route` is on, the widget keeps `default dev <iface>` in the routing
table while connected (re-applied each poll, since `gpclient` rewrites routes for
a few seconds after the tunnel comes up) and removes it on disconnect.
