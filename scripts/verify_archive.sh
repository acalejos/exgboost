#!/usr/bin/env bash
set -euo pipefail
archive=$1
target=$2
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
tar -xzf "$archive" -C "$stage"
[[ -f "$stage/libexgboost.so" ]]
[[ -f "$stage/licenses/XGBoost-LICENSE" ]]
[[ -f "$stage/licenses/dmlc-core-LICENSE" ]]
[[ -f "$stage/licenses/yyjson-LICENSE" ]]
case "$target" in
  aarch64-*) arch='aarch64|arm64' ;;
  x86_64-*) arch='x86-64|x86_64' ;;
  *) echo "Unsupported target: $target" >&2; exit 1 ;;
esac
for library in "$stage/libexgboost.so" "$stage"/lib/*; do
  file -L "$library" | tee /dev/stderr | grep -Eq "$arch"
  if [[ "$target" == *apple* ]]; then
    minimum=$(otool -l "$library" | awk '/minos / {value=$2} /LC_VERSION_MIN_MACOSX/ {legacy=1} legacy && /version / {value=$2; legacy=0} END {print value}')
    python3 - "$minimum" <<'PY'
import sys
value = sys.argv[1]
if not value or tuple(map(int, value.split('.'))) > (14, 0, 0)[:len(value.split('.'))]:
    raise SystemExit(f'Library requires macOS {value or "unknown"}; advertised baseline is 14.0')
PY
    # Only system paths and library-relative references are allowed.
    otool -L "$library" | tail -n +2 | awk '{print $1}' | while IFS= read -r dependency; do
      case "$dependency" in
        @loader_path/*|@rpath/*|/usr/lib/*|/System/Library/*) ;;
        *) echo "Nonportable dependency: $dependency" >&2; exit 1 ;;
      esac
    done
  else
    if ldd "$library" | grep -q 'not found'; then
      echo "Missing shared library for $library" >&2
      exit 1
    fi
  fi
done
# Archive names must agree with the architecture we actually inspected.
[[ "$(basename "$archive")" == *"-$target-"* ]]
