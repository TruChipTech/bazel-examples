#!/usr/bin/env bash
set -euo pipefail
# $1 = input path, $2 = output path
tr '[:lower:]' '[:upper:]' < "$1" > "$2"
