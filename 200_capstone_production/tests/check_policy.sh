#!/usr/bin/env bash
# Architectural policy: the client must not depend on server internals.
set -uo pipefail

DEPS="200_capstone_production/tests/client_deps"
FORBIDDEN="200_capstone_production/server"

[[ -f "$DEPS" ]] || { echo "FAIL: $DEPS not found"; exit 1; }

if grep -q "$FORBIDDEN" "$DEPS"; then
  echo "POLICY VIOLATION: the client depends on server internals:"
  grep "$FORBIDDEN" "$DEPS" | sed 's/^/  /'
  exit 1
fi
echo "PASS: client does not depend on the server"
