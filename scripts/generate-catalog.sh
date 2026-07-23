#!/usr/bin/env sh
# Thin wrapper so this fits the same `scripts/*.sh` convention as
# test-templates.sh. The actual logic is in Python — building a stable,
# duplicate-checked JSON index is much less error-prone there than in POSIX
# sh string handling.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
exec python3 "$ROOT/scripts/generate-catalog.py" "$@"
