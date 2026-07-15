#!/system/bin/sh

set -u

DATADIR=/data/adb/cliproxyapi
MODULE_DIR=${0%/*}
case "$MODULE_DIR" in
  /*) ;;
  *) MODULE_DIR=/data/adb/modules/cliproxyapi ;;
esac

CONFIG="$DATADIR/config.yaml"
BINARY="$MODULE_DIR/bin/cli-proxy-api"
WATCHDOG="$MODULE_DIR/watchdog.sh"
SERVICE="$MODULE_DIR/service.sh"
APP_PID_FILE="$DATADIR/cliproxyapi.pid"
WATCHDOG_PID_FILE="$DATADIR/watchdog.pid"
HEALTH_URL=http://127.0.0.1:8317/healthz
MIN_LENGTH=8

WORKDIR=
STTY_STATE=
ECHO_DISABLED=0
PASSWORD=
CONFIRMATION=
REPLY=

cleanup() {
  if [ "$ECHO_DISABLED" -eq 1 ] && [ -n "$STTY_STATE" ]; then
    stty "$STTY_STATE" </dev/tty 2>/dev/null || true
  fi
  PASSWORD=
  CONFIRMATION=
  REPLY=
  if [ -n "$WORKDIR" ] && [ -d "$WORKDIR" ]; then
    rm -rf "$WORKDIR"
  fi
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

trap cleanup EXIT
trap 'exit 130' HUP INT TERM

read_hidden() {
  prompt=$1
  printf '%s' "$prompt" >/dev/tty
  stty -echo </dev/tty || die "cannot disable terminal echo"
  ECHO_DISABLED=1
  if ! IFS= read -r REPLY </dev/tty; then
    printf '\n' >/dev/tty
    die "password input was cancelled"
  fi
  stty "$STTY_STATE" </dev/tty || die "cannot restore terminal settings"
  ECHO_DISABLED=0
  printf '\n' >/dev/tty
}

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
    kill "$pid" 2>/dev/null || true
    seconds=10
    while [ "$seconds" -gt 0 ] && pid_matches "$pid" "$expected"; do
      sleep 1
      seconds=$((seconds - 1))
    done
    if pid_matches "$pid" "$expected"; then
      kill -9 "$pid" 2>/dev/null || true
    fi
  fi
  rm -f "$pid_file"
}

health_reachable() {
  if [ -x /system/bin/curl ]; then
    /system/bin/curl -fsS --max-time 3 "$HEALTH_URL" >/dev/null 2>&1
    return $?
  fi
  if [ -x /data/data/com.termux/files/usr/bin/curl ]; then
    /data/data/com.termux/files/usr/bin/curl -fsS --max-time 3 "$HEALTH_URL" >/dev/null 2>&1
    return $?
  fi
  awk '$2 ~ /:207D$/ && $4 == "0A" { found=1 } END { exit !found }' /proc/net/tcp /proc/net/tcp6 2>/dev/null
}

wait_for_health() {
  seconds=60
  while [ "$seconds" -gt 0 ]; do
    pid=$(cat "$APP_PID_FILE" 2>/dev/null)
    if pid_matches "$pid" "$BINARY" && health_reachable; then
      return 0
    fi
    sleep 1
    seconds=$((seconds - 1))
  done
  return 1
}

restart_service() {
  touch "$DATADIR/stop"
  stop_owned_pid "$WATCHDOG_PID_FILE" "$WATCHDOG"
  stop_owned_pid "$APP_PID_FILE" "$BINARY"
  rm -f "$DATADIR/stop"

  if [ -f "$DATADIR/disable" ]; then
    return 2
  fi
  sh "$SERVICE" >/dev/null 2>&1 || return 1
  wait_for_health
}

[ -f "$CONFIG" ] || die "missing config: $CONFIG"
[ -x "$BINARY" ] || die "missing CLIProxyAPI binary: $BINARY"
[ -f "$SERVICE" ] || die "missing service script: $SERVICE"

STTY_STATE=$(stty -g </dev/tty 2>/dev/null) || die "run this command from an interactive terminal"

printf '%s\n' "CLIProxyAPI dashboard password setup"
printf '%s\n' "Use at least $MIN_LENGTH characters. Input is hidden."
read_hidden "New dashboard password: "
PASSWORD=$REPLY
REPLY=
read_hidden "Confirm dashboard password: "
CONFIRMATION=$REPLY
REPLY=

[ "$PASSWORD" = "$CONFIRMATION" ] || die "passwords do not match"
[ "${#PASSWORD}" -ge "$MIN_LENGTH" ] || die "password must contain at least $MIN_LENGTH characters"
if printf '%s' "$PASSWORD" | LC_ALL=C grep -q '[[:cntrl:]]'; then
  die "password must not contain control characters"
fi

umask 077
WORKDIR=$(mktemp -d "$DATADIR/.dashboard-password.XXXXXX") || die "cannot create secure temporary directory"
ORIGINAL="$WORKDIR/config.original"
SECRET_LINE="$WORKDIR/secret-line"
CANDIDATE="$WORKDIR/config.new"
cp "$CONFIG" "$ORIGINAL" || die "cannot back up current config"

ESCAPED=$(printf '%s' "$PASSWORD" | sed "s/'/''/g") || die "cannot encode password"
printf "  secret-key: '%s'\n" "$ESCAPED" > "$SECRET_LINE" || die "cannot stage password"
PASSWORD=
CONFIRMATION=
ESCAPED=

ALL_SECTIONS=$(grep -Ec '^remote-management:' "$CONFIG" 2>/dev/null)
BLOCK_SECTIONS=$(grep -Ec '^remote-management:[[:space:]]*(#.*)?$' "$CONFIG" 2>/dev/null)
[ "$ALL_SECTIONS" -eq "$BLOCK_SECTIONS" ] || die "inline remote-management YAML is not supported; convert it to a block first"
[ "$BLOCK_SECTIONS" -le 1 ] || die "config contains duplicate remote-management sections"

awk -v secret_file="$SECRET_LINE" '
  BEGIN {
    if ((getline secret_line < secret_file) < 1) exit 2
    close(secret_file)
  }
  function write_secret() {
    if (!wrote_secret) {
      print secret_line
      wrote_secret=1
    }
  }
  /^remote-management:[[:space:]]*(#.*)?$/ {
    seen_section=1
    in_section=1
    print
    next
  }
  in_section && /^[^[:space:]#][^:]*:/ {
    write_secret()
    in_section=0
  }
  in_section && /^[[:space:]]+secret-key:[[:space:]]*/ {
    write_secret()
    next
  }
  { print }
  END {
    if (in_section) write_secret()
    if (!seen_section) {
      if (NR > 0) print ""
      print "remote-management:"
      print "  allow-remote: false"
      print secret_line
    }
  }
' "$CONFIG" > "$CANDIDATE" || die "cannot update config"

[ "$(grep -Ec '^remote-management:' "$CANDIDATE" 2>/dev/null)" -eq 1 ] || die "generated config has an invalid remote-management section"
[ "$(grep -Ec '^  secret-key:' "$CANDIDATE" 2>/dev/null)" -eq 1 ] || die "generated config has an invalid secret-key entry"

chmod 0600 "$CANDIDATE" || die "cannot secure generated config"
chown 0:0 "$CANDIDATE" || die "cannot set generated config ownership"
CONTEXT=$(stat -c %C "$CONFIG" 2>/dev/null)
if [ -n "$CONTEXT" ] && [ "$CONTEXT" != "?" ]; then
  chcon "$CONTEXT" "$CANDIDATE" 2>/dev/null || die "cannot preserve config SELinux context"
fi
mv -f "$CANDIDATE" "$CONFIG" || die "cannot replace config"

printf '%s\n' "Password saved securely. Restarting CLIProxyAPI..."
restart_service
RESTART_STATUS=$?
case "$RESTART_STATUS" in
  0)
    printf '%s\n' "Dashboard password updated and service is healthy."
    printf '%s\n' "Dashboard: http://127.0.0.1:8317/management.html"
    ;;
  2)
    printf '%s\n' "Dashboard password updated. Service remains disabled by $DATADIR/disable."
    ;;
  *)
    printf '%s\n' "New configuration did not become healthy; restoring the previous config." >&2
    cp "$ORIGINAL" "$CONFIG" || die "rollback failed; restore $CONFIG manually"
    chmod 0600 "$CONFIG" 2>/dev/null || true
    restart_service >/dev/null 2>&1 || true
    die "password was not changed because the health check failed"
    ;;
esac
