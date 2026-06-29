#!/system/bin/sh

DATADIR=/data/adb/cliproxyapi
for file in "$DATADIR/cliproxyapi.pid" "$DATADIR/watchdog.pid"; do
  [ -f "$file" ] || continue
  pid=$(cat "$file" 2>/dev/null)
  [ -n "$pid" ] && kill "$pid" 2>/dev/null
  rm -f "$file"
done
