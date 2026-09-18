#!/usr/bin/env bash
# Verifies the release artifact is complete and correctly laid out.
set -euo pipefail

TARBALL="200_capstone_production/release.tar.gz"
WORK="${TEST_TMPDIR:-/tmp}/capstone.$$"
mkdir -p "$WORK"
tar xzf "$TARBALL" -C "$WORK"

echo "--- release contents ---"
(cd "$WORK" && find . -type f | sort)

fail() { echo "FAIL: $1"; exit 1; }

[[ -f "$WORK/opt/telemetry/bin/collector" ]] || fail "collector binary missing"
[[ -x "$WORK/opt/telemetry/bin/collector" ]] || fail "collector is not executable"
[[ -f "$WORK/opt/telemetry/manifest.json" ]] || fail "provenance manifest missing"

grep -q '"app"' "$WORK/opt/telemetry/manifest.json" || fail "manifest malformed"

echo "PASS: release artifact is complete and well formed"
