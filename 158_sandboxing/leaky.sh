#!/usr/bin/env bash
# Demonstrates that the sandbox hides undeclared files.
set -uo pipefail

DECLARED="158_sandboxing/declared.txt"
UNDECLARED="158_sandboxing/undeclared.txt"

echo "declared file:"
if [[ -f "$DECLARED" ]]; then
  echo "  FOUND  - it was listed in data"
else
  echo "  MISSING - unexpected!"
  exit 1
fi

echo "undeclared file:"
if [[ -f "$UNDECLARED" ]]; then
  echo "  FOUND  - the sandbox is NOT active (this would be a hermeticity bug)"
else
  echo "  MISSING - correct: the sandbox hides undeclared inputs"
fi
exit 0
