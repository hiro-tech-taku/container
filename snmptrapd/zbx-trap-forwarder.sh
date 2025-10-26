#!/bin/sh
set -eu

# This script reads a trap from stdin and forwards it to Zabbix using zabbix_sender.
# Required env: ZBX_SERVER; optional: ZBX_PORT (10051), ZBX_HOST, ZBX_KEY (snmptrap)

ZBX_SERVER="${ZBX_SERVER:-}"
ZBX_PORT="${ZBX_PORT:-10051}"
ZBX_HOST="${ZBX_HOST:-}"
ZBX_KEY="${ZBX_KEY:-snmptrap}"

if [ -z "$ZBX_SERVER" ]; then
  echo "[zbx-trap-forwarder] ZBX_SERVER is not set; skipping." >&2
  exit 0
fi

# Read entire stdin (trap content)
TRAP_RAW="$(cat || true)"

# Derive a target host if not specified: fallback to source IP parsed from first line
TARGET_HOST="$ZBX_HOST"
if [ -z "$TARGET_HOST" ]; then
  # Common snmptrapd textual format contains the source in the first line
  first_line=$(printf '%s' "$TRAP_RAW" | head -n 1)
  # Try to grab an IPv4 address
  src_ip=$(printf '%s' "$first_line" | sed -n 's/.*\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\).*/\1/p' | head -n 1 || true)
  if [ -n "$src_ip" ]; then
    TARGET_HOST="$src_ip"
  else
    TARGET_HOST="unknown-snmptrap-source"
  fi
fi

# Collapse newlines to spaces for a single-line value to avoid sender parsing issues
VALUE=$(printf '%s' "$TRAP_RAW" | tr '\r' ' ' | tr '\n' ' ')

# Send to Zabbix
zabbix_sender -z "$ZBX_SERVER" -p "$ZBX_PORT" -s "$TARGET_HOST" -k "$ZBX_KEY" -o "$VALUE" >/dev/null 2>&1 \
  && echo "[zbx-trap-forwarder] sent trap to $ZBX_SERVER:$ZBX_PORT host=$TARGET_HOST key=$ZBX_KEY" >&2 \
  || echo "[zbx-trap-forwarder] failed to send trap to $ZBX_SERVER:$ZBX_PORT host=$TARGET_HOST" >&2

exit 0

