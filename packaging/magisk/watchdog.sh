#!/system/bin/sh

MODDIR=${0%/*}
DATADIR=/data/adb/cliproxyapi
BINARY="$MODDIR/bin/cli-proxy-api"
CONFIG="$DATADIR/config.yaml"
DEFAULT_CONFIG="$MODDIR/config/config.yaml"
STATIC_DIR="$DATADIR/static"
APP_LOG="$DATADIR/cliproxyapi.log"
PIDFILE="$DATADIR/cliproxyapi.pid"
DISABLE="$DATADIR/disable"
STOP="$DATADIR/stop"
INTERVAL=10
BOOT_DELAY=20

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') $*"
}

start_app() {
  [ -x "$BINARY" ] || { log "missing binary: $BINARY"; return 1; }
  mkdir -p "$DATADIR/auths" "$DATADIR/logs" "$STATIC_DIR"
  [ -f "$CONFIG" ] || cp "$DEFAULT_CONFIG" "$CONFIG"
  if [ ! -f "$STATIC_DIR/management.html" ] && [ -f "$MODDIR/static/management.html" ]; then
    cp "$MODDIR/static/management.html" "$STATIC_DIR/management.html"
    chmod 0644 "$STATIC_DIR/management.html"
  fi
  cd "$DATADIR" || return 1
  GODEBUG=netdns=cgo MANAGEMENT_STATIC_PATH="$STATIC_DIR" nohup "$BINARY" --config "$CONFIG" >> "$APP_LOG" 2>&1 &
  echo $! > "$PIDFILE"
  log "started cli-proxy-api pid=$!"
}

stop_app() {
  if [ -f "$PIDFILE" ]; then
    pid=$(cat "$PIDFILE" 2>/dev/null)
    [ -n "$pid" ] && kill "$pid" 2>/dev/null
    rm -f "$PIDFILE"
  fi
}

trap 'stop_app; rm -f /data/adb/cliproxyapi/watchdog.pid; exit 0' INT TERM EXIT

sleep "$BOOT_DELAY"

while true; do
  if [ -f "$DISABLE" ] || [ -f "$STOP" ]; then
    stop_app
    log "disabled; watchdog exit"
    rm -f "$STOP"
    exit 0
  fi

  pid=""
  [ -f "$PIDFILE" ] && pid=$(cat "$PIDFILE" 2>/dev/null)

  if [ -z "$pid" ] || ! kill -0 "$pid" 2>/dev/null; then
    [ -n "$pid" ] && log "process dead pid=$pid; restarting"
    start_app
  fi

  sleep "$INTERVAL"
done
