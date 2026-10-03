#!/usr/bin/env bash
set -euo pipefail
archive=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
# Compile BEAM files, then replace every native file with the archived distribution.
EXGBOOST_BUILD=true mix compile --warnings-as-errors
priv="${MIX_BUILD_PATH:-_build/${MIX_ENV:-dev}}/lib/exgboost/priv"
rm -rf "$priv"
mkdir -p "$priv"
tar -xzf "$archive" -C "$priv"
# A fresh VM must load the packaged NIF, with compilation disabled.
EXGBOOST_BUILD=false mix run --no-compile scripts/smoke.exs
