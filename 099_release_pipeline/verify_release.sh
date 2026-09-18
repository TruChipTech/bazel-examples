#!/usr/bin/env bash
# Verifies the release artifact contains everything it should.
set -euo pipefail

TARBALL="099_release_pipeline/release.tar.gz"
WORK="${TEST_TMPDIR:-/tmp}/verify.$$"
mkdir -p "$WORK"
tar xzf "$TARBALL" -C "$WORK"

echo "--- archive contents ---"
(cd "$WORK" && find . -type f | sort)

fail() { echo "FAIL: $1"; exit 1; }

[[ -f "$WORK/opt/demo-app/config/app.yaml" ]] || fail "config missing"
[[ -f "$WORK/opt/demo-app/VERSION" ]]         || fail "VERSION missing"
grep -q "^name: demo-app" "$WORK/opt/demo-app/config/app.yaml" || fail "config corrupt"

echo "PASS: release artifact is well formed"
