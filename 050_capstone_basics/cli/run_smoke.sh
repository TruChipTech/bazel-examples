#!/usr/bin/env bash
set -euo pipefail

BIN="050_capstone_basics/cli/analyze"
DATA="050_capstone_basics/testdata/values.txt"

output="$("$BIN" "$DATA")"
echo "$output"

echo "$output" | grep -q "count = 5"   || { echo "FAIL: wrong count"; exit 1; }
echo "$output" | grep -q "max   = 47"  || { echo "FAIL: wrong max";   exit 1; }
echo "PASS: end-to-end smoke test"
