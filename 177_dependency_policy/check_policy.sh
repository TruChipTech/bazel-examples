#!/usr/bin/env bash
# Fails if the public API's dependency closure contains anything internal.
set -uo pipefail

DEPS_FILE="177_dependency_policy/api_deps"
FORBIDDEN="177_dependency_policy/internal"

if [[ ! -f "$DEPS_FILE" ]]; then
  echo "FAIL: dependency listing not found at $DEPS_FILE"
  exit 1
fi

echo "checking the dependency closure of //...public_api:api"
if grep -q "$FORBIDDEN" "$DEPS_FILE"; then
  echo "POLICY VIOLATION: the public API depends on internal code:"
  grep "$FORBIDDEN" "$DEPS_FILE" | sed 's/^/  /'
  exit 1
fi

echo "PASS: no internal dependencies in the public API closure"
exit 0
