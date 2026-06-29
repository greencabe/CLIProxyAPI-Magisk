#!/usr/bin/env sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUT="$ROOT/dist"
ZIP="$OUT/cliproxyapi-magisk.zip"

rm -rf "$OUT"
mkdir -p "$OUT"
[ -x "$ROOT/bin/cli-proxy-api" ] || { echo "missing executable: bin/cli-proxy-api" >&2; exit 1; }
cd "$ROOT"
python3 scripts/zip_module.py "$ZIP"
echo "$ZIP"
