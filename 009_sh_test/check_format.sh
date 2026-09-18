#!/usr/bin/env bash
# Verifies that the data file has the expected shape.
set -euo pipefail

DATA="009_sh_test/config.ini"

if [[ ! -f "$DATA" ]]; then
  echo "FAIL: cannot find $DATA (cwd=$(pwd))"
  exit 1
fi

if ! grep -q '^\[server\]' "$DATA"; then
  echo "FAIL: missing [server] section"
  exit 1
fi

if ! grep -q '^port = [0-9]\+$' "$DATA"; then
  echo "FAIL: missing or malformed port"
  exit 1
fi

echo "PASS: config.ini is well formed"
