#!/usr/bin/env bash
# End-to-end: C++ writes the file, Python reads it back.
set -euo pipefail

WRITER="098_multi_language/cc/writer"
READER="098_multi_language/py/reader"
DATA="${TEST_TMPDIR:-/tmp}/metrics.bin"

"$WRITER" "$DATA"
output="$("$READER" "$DATA")"
echo "$output"

echo "$output" | grep -q "read 2 metrics"      || { echo "FAIL: wrong count";  exit 1; }
echo "$output" | grep -q "cpu_usage = 0.73"    || { echo "FAIL: wrong value";  exit 1; }
echo "$output" | grep -q "host=web-01"         || { echo "FAIL: labels lost";  exit 1; }
echo "PASS: C++ and Python agree on the wire format"
