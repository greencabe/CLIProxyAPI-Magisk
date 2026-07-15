#!/system/bin/sh

DATADIR=/data/adb/cliproxyapi
mkdir -p "$DATADIR/auths" "$DATADIR/logs" "$DATADIR/static"
chmod 0700 "$DATADIR" "$DATADIR/auths" "$DATADIR/logs"
chmod 0755 "$DATADIR/static"

# PID files do not survive a reboot safely: Android may reuse either PID before
# service.sh gets a chance to inspect it.
rm -f "$DATADIR/cliproxyapi.pid" "$DATADIR/watchdog.pid" "$DATADIR/stop"
