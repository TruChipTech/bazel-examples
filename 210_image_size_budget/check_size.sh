#!/usr/bin/env bash
set -uo pipefail
limit="$1"
layer="210_image_size_budget/layer.tar"
actual=$(wc -c < "$layer")
echo "layer size: $actual bytes (limit $limit)"
if [ "$actual" -gt "$limit" ]; then
  echo "FAIL: layer exceeds budget by $((actual - limit)) bytes"
  echo "      Inspect with: tar tvf bazel-bin/$layer | sort -k3 -rn | head"
  exit 1
fi
echo "PASS: within budget ($(( limit - actual )) bytes to spare)"
