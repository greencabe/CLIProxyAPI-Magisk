#!/system/bin/sh

DATADIR=/data/adb/cliproxyapi
mkdir -p "$DATADIR/auths" "$DATADIR/logs"
chmod 0700 "$DATADIR" "$DATADIR/auths" "$DATADIR/logs"
