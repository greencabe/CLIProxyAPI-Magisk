# CLIProxyAPI Magisk

Run [CLIProxyAPI](https://github.com/router-for-me/CLIProxyAPI) as a Magisk boot service on rooted Android.

Author: Rofiq

## What It Does

- Starts CLIProxyAPI automatically after boot.
- Restarts CLIProxyAPI when it crashes.
- Keeps editable runtime data outside module path.
- Tracks upstream CLIProxyAPI releases with GitHub Actions.
- Publishes a Magisk ZIP release using the same upstream version tag.
- Updates `update.json` for Magisk update checks.

## Runtime Paths

- Config: `/data/adb/cliproxyapi/config.yaml`
- Auth files: `/data/adb/cliproxyapi/auths`
- App log: `/data/adb/cliproxyapi/cliproxyapi.log`
- Watchdog log: `/data/adb/cliproxyapi/watchdog.log`
- Disable flag: `/data/adb/cliproxyapi/disable`
- Stop once: `/data/adb/cliproxyapi/stop`

## Default Endpoint

```text
http://127.0.0.1:8317
```

For LAN access, edit `/data/adb/cliproxyapi/config.yaml`:

```yaml
host: "0.0.0.0"
port: 8317
```

## Manual Control

```sh
su -c 'touch /data/adb/cliproxyapi/disable'
su -c 'rm /data/adb/cliproxyapi/disable'
su -c 'touch /data/adb/cliproxyapi/stop'
su -c 'tail -f /data/adb/cliproxyapi/watchdog.log'
su -c 'tail -f /data/adb/cliproxyapi/cliproxyapi.log'
```

## Build Locally

Put upstream binary at `bin/cli-proxy-api`, then run:

```sh
./scripts/build.sh
```

Output:

```text
dist/cliproxyapi-magisk.zip
```

## Auto Release

`.github/workflows/release.yml` checks latest upstream release from `router-for-me/CLIProxyAPI`, downloads `linux_aarch64` binary, updates `module.prop`, builds ZIP, then creates/updates GitHub release with the same tag.
