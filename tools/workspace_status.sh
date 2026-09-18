#!/usr/bin/env bash
# Emitted key/value pairs become available to stamped rules.
# Keys starting with STABLE_ force a rebuild when they change;
# other keys do not. See samples 094, 095 and 173.
set -euo pipefail

echo "BUILD_TIMESTAMP $(date +%s)"
echo "BUILD_HOST $(hostname)"
echo "BUILD_USER ${USER:-unknown}"

if git rev-parse --git-dir >/dev/null 2>&1; then
  echo "STABLE_GIT_COMMIT $(git rev-parse HEAD)"
  echo "STABLE_GIT_BRANCH $(git rev-parse --abbrev-ref HEAD)"
else
  echo "STABLE_GIT_COMMIT unknown"
  echo "STABLE_GIT_BRANCH unknown"
fi
