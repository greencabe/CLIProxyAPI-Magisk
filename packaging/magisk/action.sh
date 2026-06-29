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
  [ -f "$file" ] || return 1
  pid=$(cat "$file" 2>/dev/null)
  [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null
}

printf '%b\n' "${BOLD}${CYAN}CLIProxyAPI Health Check${RESET}"
printf '%b\n' "${GRAY}$(date)${RESET}"
echo

if [ -x "$BIN" ]; then
  ok "binary installed: $BIN"
else
  fail "binary missing: $BIN"
fi

if pid_alive "$WATCHDOG_PID_FILE"; then
  ok "watchdog running: pid $(cat "$WATCHDOG_PID_FILE" 2>/dev/null)"
else
  fail "watchdog not running"
fi

if pid_alive "$APP_PID_FILE"; then
  ok "cli-proxy-api running: pid $(cat "$APP_PID_FILE" 2>/dev/null)"
else
  fail "cli-proxy-api not running"
fi

if ss -ltn 2>/dev/null | grep -q '127.0.0.1:8317'; then
  ok "API port listening: 127.0.0.1:8317"
else
  fail "API port not listening: 127.0.0.1:8317"
fi

health=$(curl -sS --max-time 5 "$URL" 2>/dev/null || true)
if [ -n "$health" ]; then
  ok "health endpoint reachable: $URL"
else
  fail "health endpoint unreachable: $URL"
fi

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
