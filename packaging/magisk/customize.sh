#!/system/bin/sh

SKIPUNZIP=0
DATADIR=/data/adb/cliproxyapi
BIN="$MODPATH/bin/cli-proxy-api"

ui_print "- CLIProxyAPI Magisk"
ui_print "- Author: Rofiq"
ui_print "- Arch: $ARCH"

[ "$ARCH" = "arm64" ] || abort "Unsupported arch: $ARCH. Need arm64-v8a."

DEVICE_API=${API:-$(getprop ro.build.version.sdk 2>/dev/null)}
case "$DEVICE_API" in
  ''|*[!0-9]*) abort "Cannot determine Android API level." ;;
esac
[ "$DEVICE_API" -ge 24 ] || abort "Unsupported Android API $DEVICE_API. Need Android 7.0 / API 24 or newer."

[ -f "$BIN" ] || abort "Missing bundled binary: bin/cli-proxy-api"

mkdir -p "$DATADIR/auths" "$DATADIR/logs" "$DATADIR/static"
chmod 0700 "$DATADIR" "$DATADIR/auths" "$DATADIR/logs"
chmod 0755 "$DATADIR/static"

if [ -f "$MODPATH/static/management.html" ]; then
  cp "$MODPATH/static/management.html" "$DATADIR/static/management.html" || abort "Dashboard copy failed"
  chmod 0644 "$DATADIR/static/management.html"
  ui_print "- Installed dashboard: $DATADIR/static/management.html"
fi

if [ ! -f "$DATADIR/config.yaml" ]; then
  cp "$MODPATH/config/config.yaml" "$DATADIR/config.yaml" || abort "Config copy failed"
  ui_print "- Created config: $DATADIR/config.yaml"
else
  ui_print "- Kept config: $DATADIR/config.yaml"
fi

chmod 0755 "$BIN" "$MODPATH/service.sh" "$MODPATH/watchdog.sh" "$MODPATH/post-fs-data.sh" "$MODPATH/uninstall.sh" "$MODPATH/action.sh" "$MODPATH/set-dashboard-password.sh"
chmod 0600 "$DATADIR/config.yaml"
TERMUX_BIN=/data/data/com.termux/files/usr/bin
if [ -d "$TERMUX_BIN" ] && [ -f "$MODPATH/termux-wrapper.sh" ]; then
  TERMUX_WRAPPER="$TERMUX_BIN/cliproxyapi"
  WRAPPER_OWNED=0
  if [ -f "$TERMUX_WRAPPER" ] && [ ! -L "$TERMUX_WRAPPER" ]; then
    if grep -Fqx '# Managed by CLIProxyAPI-Magisk' "$TERMUX_WRAPPER" 2>/dev/null || {
      grep -Fqx 'BIN=/data/adb/modules/cliproxyapi/bin/cli-proxy-api' "$TERMUX_WRAPPER" 2>/dev/null &&
      grep -Fqx 'CONFIG=/data/adb/cliproxyapi/config.yaml' "$TERMUX_WRAPPER" 2>/dev/null
    }; then
      WRAPPER_OWNED=1
    fi
  fi

  if [ ! -e "$TERMUX_WRAPPER" ] && [ ! -L "$TERMUX_WRAPPER" ]; then
    cp "$MODPATH/termux-wrapper.sh" "$TERMUX_WRAPPER" 2>/dev/null && chmod 0755 "$TERMUX_WRAPPER" && ui_print "- Installed Termux wrapper: $TERMUX_WRAPPER"
  elif [ "$WRAPPER_OWNED" -eq 1 ]; then
    cp "$MODPATH/termux-wrapper.sh" "$TERMUX_WRAPPER" 2>/dev/null && chmod 0755 "$TERMUX_WRAPPER" && ui_print "- Updated Termux wrapper: $TERMUX_WRAPPER"
  else
    ui_print "! Kept existing Termux command (not owned by this module): $TERMUX_WRAPPER"
  fi
fi

ui_print "- Endpoint default: http://127.0.0.1:8317"
ui_print "- Reboot to start service"
ui_print "- Disable: touch $DATADIR/disable"
