#!/usr/bin/env bash
set -uo pipefail
actual=$(cat 207_reproducible_digest/image_layout/digest.txt)
expected=$(cat 207_reproducible_digest/expected_digest.txt)
echo "expected: $expected"
echo "actual:   $actual"
if [ "$actual" != "$expected" ]; then
  echo "FAIL: image digest changed."
  echo "      If this change was intentional, update expected_digest.txt to:"
  echo "      $actual"
  exit 1
fi
echo "PASS: image digest is stable"
