#!/usr/bin/env bash
set -euo pipefail
# Use Python's standard library so this also works with macOS's bundled Bash 3.
exec python3 "$(dirname "$0")/check_xgboost_c_api.py" "$@"
