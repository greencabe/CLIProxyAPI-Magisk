# CLIProxyAPI Magisk

ARM64 Android Magisk/KernelSU/Next SU module builder for [CLIProxyAPI](https://github.com/router-for-me/CLIProxyAPI).

Author: Rofiq

This repository does not fork CLIProxyAPI source code. GitHub Actions downloads official upstream release assets, overlays the Magisk packaging files, bundles the dashboard, then publishes a release with the same upstream tag.

## Release Flow

- Scheduled workflow checks latest upstream CLIProxyAPI release every 6 hours.
- If this repo has no release with that tag, it builds `cliproxyapi-magisk.zip`.
- Manual workflow can build latest or a specific upstream tag.
- `force=true` rebuilds an existing release.

## Runtime Behavior

- Starts CLIProxyAPI after Android boot.
- Restarts CLIProxyAPI if it crashes.
- Bundles `management.html` dashboard for offline first run.
- Adds root-manager WebUI redirect to the CLIProxyAPI dashboard.
- Adds root-manager action health check.
- Stores config/state in `/data/adb/cliproxyapi`.
- Writes logs to `/data/adb/cliproxyapi`.
- Serves API at `http://127.0.0.1:8317` by default.

Disable autostart:

```sh
touch /data/adb/cliproxyapi/disable
```

Stop once:

```sh
touch /data/adb/cliproxyapi/stop
```

## Paths

- Config: `/data/adb/cliproxyapi/config.yaml`
- Auth files: `/data/adb/cliproxyapi/auths`
- App log: `/data/adb/cliproxyapi/cliproxyapi.log`
- Watchdog log: `/data/adb/cliproxyapi/watchdog.log`
- Dashboard: `/data/adb/cliproxyapi/static/management.html`

## LAN Access

Edit `/data/adb/cliproxyapi/config.yaml`:

```yaml
host: "0.0.0.0"
port: 8317
```

## Manual Build In Actions

Open **Actions → Release Magisk Module → Run workflow**.

- `upstream_tag` empty: build latest upstream release.
- `upstream_tag=v7.2.45`: build specific release tag.
- `force=true`: rebuild even if release exists.

## Local Build

Put files here:

```text
packaging/magisk/bin/cli-proxy-api
packaging/magisk/static/management.html
```

Then run:

```sh
VERSION=v7.2.45 VERSION_CODE=7002045 ./packaging/magisk/build-module.sh
```

Output:

```text
dist/magisk/cliproxyapi-magisk.zip
```
