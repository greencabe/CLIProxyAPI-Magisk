#!/system/bin/sh

MODDIR=${0%/*}
DATADIR=/data/adb/cliproxyapi
WATCHDOG="$MODDIR/watchdog.sh"
PIDFILE="$DATADIR/watchdog.pid"
LOG="$DATADIR/watchdog.log"

[ -f "$DATADIR/disable" ] && exit 0
[ -x "$WATCHDOG" ] || exit 0

mkdir -p "$DATADIR/auths" "$DATADIR/logs"

if [ -f "$PIDFILE" ]; then
  pid=$(cat "$PIDFILE" 2>/dev/null)
  [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null && exit 0
fi

nohup "$WATCHDOG" >> "$LOG" 2>&1 &
echo $! > "$PIDFILE"
