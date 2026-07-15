#!/system/bin/sh

DATA_DIR=/data/adb/cliproxyapi
MODULE_DIR=/data/adb/modules/cliproxyapi
BIN=$MODULE_DIR/bin/cli-proxy-api
APP_PID_FILE=$DATA_DIR/cliproxyapi.pid
WATCHDOG_PID_FILE=$DATA_DIR/watchdog.pid
APP_LOG=$DATA_DIR/cliproxyapi.log
WATCHDOG_LOG=$DATA_DIR/watchdog.log
DASHBOARD=$DATA_DIR/static/management.html
URL=http://127.0.0.1:8317/healthz
DASHBOARD_URL=http://127.0.0.1:8317/management.html

RESET='\033[0m'
BOLD='\033[1m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
CYAN='\033[36m'
GRAY='\033[90m'

ok() { printf '%b\n' "${GREEN}✓${RESET} $*"; }
warn() { printf '%b\n' "${YELLOW}⚠${RESET} $*"; }
fail() { printf '%b\n' "${RED}✗${RESET} $*"; }
info() { printf '%b\n' "${CYAN}›${RESET} $*"; }

pid_alive() {
  file=$1
  expected=$2
  [ -f "$file" ] || return 1
  pid=$(cat "$file" 2>/dev/null)
  case "$pid" in
    ''|*[!0-9]*) return 1 ;;
  esac
  [ -r "/proc/$pid/cmdline" ] || return 1
  kill -0 "$pid" 2>/dev/null || return 1
  tr '\000' '\n' < "/proc/$pid/cmdline" 2>/dev/null | grep -Fqx "$expected"
}

port_listening() {
  if command -v ss >/dev/null 2>&1; then
    ss -ltn 2>/dev/null | grep -Eq '(^|[[:space:]])[^[:space:]]*:8317([[:space:]]|$)' && return 0
  fi
  if command -v netstat >/dev/null 2>&1; then
    netstat -ltn 2>/dev/null | grep -Eq '(^|[[:space:]])[^[:space:]]*:8317([[:space:]]|$)' && return 0
  fi
  for socket_table in /proc/net/tcp /proc/net/tcp6; do
    [ -r "$socket_table" ] || continue
    awk '$2 ~ /:207D$/ && $4 == "0A" { found=1 } END { exit !found }' "$socket_table" 2>/dev/null && return 0
  done
  return 1
}

health_reachable() {
  if command -v curl >/dev/null 2>&1; then
    HTTP_CLIENT=curl
    curl -fsS --max-time 5 "$URL" >/dev/null 2>&1
    return $?
  fi
  if command -v wget >/dev/null 2>&1; then
    HTTP_CLIENT=wget
    wget -q -T 5 -O /dev/null "$URL" >/dev/null 2>&1
    return $?
  fi
  HTTP_CLIENT=none
  return 2
}

printf '%b\n' "${BOLD}${CYAN}CLIProxyAPI Health Check${RESET}"
printf '%b\n' "${GRAY}$(date)${RESET}"
echo

if [ -x "$BIN" ]; then
  ok "binary installed: $BIN"
else
  fail "binary missing: $BIN"
fi

if pid_alive "$WATCHDOG_PID_FILE" "$MODULE_DIR/watchdog.sh"; then
  ok "watchdog running: pid $(cat "$WATCHDOG_PID_FILE" 2>/dev/null)"
else
  fail "watchdog not running"
fi

if pid_alive "$APP_PID_FILE" "$BIN"; then
  ok "cli-proxy-api running: pid $(cat "$APP_PID_FILE" 2>/dev/null)"
else
  fail "cli-proxy-api not running"
fi

if port_listening; then
  ok "API TCP port listening: 8317"
else
  fail "API TCP port not listening: 8317"
fi

health_reachable
health_status=$?
case "$health_status" in
  0) ok "health endpoint reachable via $HTTP_CLIENT: $URL" ;;
  2) warn "health endpoint not requested: curl/wget unavailable" ;;
  *) fail "health endpoint unreachable via $HTTP_CLIENT: $URL" ;;
esac

if [ -f "$DASHBOARD" ]; then
  ok "dashboard bundled: $DASHBOARD"
else
  warn "dashboard file missing: $DASHBOARD"
fi

if [ -f "$DATA_DIR/disable" ]; then
  warn "autostart disabled: $DATA_DIR/disable"
else
  ok "autostart enabled"
fi

echo
printf '%b\n' "${BOLD}Dashboard${RESET}"
info "$DASHBOARD_URL"

echo
printf '%b\n' "${BOLD}Recent Watchdog Log${RESET}"
if [ -f "$WATCHDOG_LOG" ]; then
  tail -20 "$WATCHDOG_LOG"
else
  warn "log not found: $WATCHDOG_LOG"
fi

echo
printf '%b\n' "${BOLD}Recent App Log${RESET}"
if [ -f "$APP_LOG" ]; then
  tail -20 "$APP_LOG"
else
  warn "log not found: $APP_LOG"
fi
