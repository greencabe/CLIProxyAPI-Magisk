#!/system/bin/sh

DATADIR=/data/adb/cliproxyapi
MODULE_DIR=${0%/*}
case "$MODULE_DIR" in
  /*) ;;
  *) MODULE_DIR=/data/adb/modules/cliproxyapi ;;
esac
BINARY="$MODULE_DIR/bin/cli-proxy-api"
WATCHDOG="$MODULE_DIR/watchdog.sh"

pid_matches() {
  pid=$1
  expected=$2
  case "$pid" in
    ''|*[!0-9]*) return 1 ;;
  esac
  [ -r "/proc/$pid/cmdline" ] || return 1
  kill -0 "$pid" 2>/dev/null || return 1
  tr '\000' '\n' < "/proc/$pid/cmdline" 2>/dev/null | grep -Fqx "$expected"
}

stop_owned_pid() {
  pid_file=$1
  expected=$2
  pid=$(cat "$pid_file" 2>/dev/null)

  if pid_matches "$pid" "$expected"; then
    kill "$pid" 2>/dev/null
    seconds=10
    while [ "$seconds" -gt 0 ] && pid_matches "$pid" "$expected"; do
      sleep 1
      seconds=$((seconds - 1))
    done
    if pid_matches "$pid" "$expected"; then
      kill -9 "$pid" 2>/dev/null
    fi
  fi
  rm -f "$pid_file"
}

# Prevent the watchdog from racing an application restart while uninstalling.
# Stop the watchdog first; its TERM trap also asks the application to exit.
mkdir -p "$DATADIR"
touch "$DATADIR/stop"
stop_owned_pid "$DATADIR/watchdog.pid" "$WATCHDOG"
stop_owned_pid "$DATADIR/cliproxyapi.pid" "$BINARY"
rm -f "$DATADIR/stop"

TERMUX_WRAPPER=/data/data/com.termux/files/usr/bin/cliproxyapi
if [ -f "$TERMUX_WRAPPER" ] && [ ! -L "$TERMUX_WRAPPER" ] && {
  grep -Fqx '# Managed by CLIProxyAPI-Magisk' "$TERMUX_WRAPPER" 2>/dev/null ||
  { grep -Fqx 'BIN=/data/adb/modules/cliproxyapi/bin/cli-proxy-api' "$TERMUX_WRAPPER" 2>/dev/null &&
    grep -Fqx 'CONFIG=/data/adb/cliproxyapi/config.yaml' "$TERMUX_WRAPPER" 2>/dev/null; }
}; then
  rm -f "$TERMUX_WRAPPER"
fi
