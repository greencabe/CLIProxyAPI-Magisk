# CLIProxyAPI Magisk Packaging

This directory is the Magisk module source. Release workflow injects:

- `bin/cli-proxy-api`
- `static/management.html`
- `webroot/index.html` root-manager WebUI redirect
- generated `module.prop`
- repository `LICENSE` and `THIRD_PARTY_NOTICES.md`

Then `build-module.sh` creates `dist/magisk/cliproxyapi-magisk.zip`.
