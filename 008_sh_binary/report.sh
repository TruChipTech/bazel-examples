#!/usr/bin/env bash
# A tiny shell tool wrapped as a Bazel target.
set -euo pipefail

echo "=== environment report ==="
echo "args     : $*"
echo "pwd      : $(pwd)"
echo "runfiles : ${RUNFILES_DIR:-<not set>}"
echo "=========================="
