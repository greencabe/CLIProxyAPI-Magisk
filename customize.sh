#!/system/bin/sh

SKIPUNZIP=0
DATADIR=/data/adb/cliproxyapi
BIN="$MODPATH/bin/cli-proxy-api"

ui_print "- CLIProxyAPI Magisk"
ui_print "- Author: Rofiq"
ui_print "- Arch: $ARCH"

[ "$ARCH" = "arm64" ] || abort "Unsupported arch: $ARCH. Need arm64-v8a."
[ -f "$BIN" ] || abort "Missing bundled binary: bin/cli-proxy-api"

mkdir -p "$DATADIR/auths" "$DATADIR/logs"
chmod 0700 "$DATADIR" "$DATADIR/auths" "$DATADIR/logs"

if [ ! -f "$DATADIR/config.yaml" ]; then
  cp "$MODPATH/config/config.yaml" "$DATADIR/config.yaml" || abort "Config copy failed"
  ui_print "- Created config: $DATADIR/config.yaml"
else
  ui_print "- Kept config: $DATADIR/config.yaml"
fi

chmod 0755 "$BIN" "$MODPATH/service.sh" "$MODPATH/watchdog.sh" "$MODPATH/post-fs-data.sh" "$MODPATH/uninstall.sh"
ui_print "- Endpoint default: http://127.0.0.1:8317"
ui_print "- Reboot to start service"
ui_print "- Disable: touch $DATADIR/disable"
