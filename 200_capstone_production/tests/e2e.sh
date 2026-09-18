#!/usr/bin/env bash
# End-to-end: the C++ collector writes, the Python reporter reads.
set -euo pipefail

COLLECTOR="200_capstone_production/server/collector"
REPORT="200_capstone_production/client/report"
DATA="${TEST_TMPDIR:-/tmp}/batch.bin"

"$COLLECTOR" "$DATA"
output="$("$REPORT" "$DATA")"
echo "$output"

echo "$output" | grep -q "source: telemetry-collector" || { echo "FAIL: wrong source"; exit 1; }
echo "$output" | grep -q "samples: 2"                  || { echo "FAIL: wrong count";  exit 1; }
echo "$output" | grep -q "cpu_usage = 0.62"            || { echo "FAIL: wrong value";  exit 1; }
echo "$output" | grep -q "\[ WARN\] disk_free_ratio"   || { echo "FAIL: wrong level";  exit 1; }

echo "PASS: C++ and Python agree across the proto boundary"
