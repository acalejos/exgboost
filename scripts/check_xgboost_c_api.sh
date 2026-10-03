#!/usr/bin/env bash
set -euo pipefail

extract_signatures() {
  local header="$1"

  awk '
    /XG[A-Za-z0-9_]+[[:space:]]*\(/ {
      in_decl=1
      decl=$0
      if ($0 ~ /;/) {
        print decl
        in_decl=0
        decl=""
      }
      next
    }
    in_decl {
      decl=decl " " $0
      if ($0 ~ /;/) {
        print decl
        in_decl=0
        decl=""
      }
    }
  ' "$header" \
    | sed -E '
        s/[[:space:]]+/ /g
        s/^[[:space:]]+//
        s/[[:space:]]+$//
        s/[[:space:]]*\*[[:space:]]*/\*/g
        s/[[:space:]]*,[[:space:]]*/,/g
        s/\([[:space:]]*/(/g
        s/[[:space:]]*\)/)/g
      ' \
    | awk '
        {
          if (match($0, /XG[A-Za-z0-9_]+[[:space:]]*\(/)) {
            name = substr($0, RSTART, RLENGTH)
            gsub(/[[:space:]]*\($/, "", name)
            print name "\t" $0
          }
        }
      '
}

compare_mode() {
  if [[ $# -ne 2 ]]; then
    echo "Usage: $0 --compare <old-xgboost-include-dir> <new-xgboost-include-dir>"
    exit 2
  fi

  local old_header="$1/xgboost/c_api.h"
  local new_header="$2/xgboost/c_api.h"

  if [[ ! -f "$old_header" ]]; then
    echo "XGBoost C API header not found: $old_header"
    exit 2
  fi

  if [[ ! -f "$new_header" ]]; then
    echo "XGBoost C API header not found: $new_header"
    exit 2
  fi

  old_tmp=$(mktemp)
  new_tmp=$(mktemp)
  trap 'rm -f "${old_tmp:-}" "${new_tmp:-}"' EXIT

  extract_signatures "$old_header" | sort -u > "$old_tmp"
  extract_signatures "$new_header" | sort -u > "$new_tmp"

  declare -A old_map=()
  declare -A new_map=()

  while IFS=$'\t' read -r name sig; do
    [[ -n "${name:-}" ]] && old_map["$name"]="$sig"
  done < "$old_tmp"

  while IFS=$'\t' read -r name sig; do
    [[ -n "${name:-}" ]] && new_map["$name"]="$sig"
  done < "$new_tmp"

  removed=()
  added=()
  changed=()

  for name in "${!old_map[@]}"; do
    if [[ -z "${new_map[$name]+x}" ]]; then
      removed+=("$name")
    elif [[ "${old_map[$name]}" != "${new_map[$name]}" ]]; then
      changed+=("$name")
    fi
  done

  for name in "${!new_map[@]}"; do
    if [[ -z "${old_map[$name]+x}" ]]; then
      added+=("$name")
    fi
  done

  if (( ${#removed[@]} == 0 && ${#changed[@]} == 0 && ${#added[@]} == 0 )); then
    echo "No C API declaration differences found between versions."
    return 0
  fi

  if (( ${#removed[@]} > 0 )); then
    printf 'Removed symbols (%d):\n' "${#removed[@]}"
    printf '  - %s\n' "${removed[@]}"
  fi

  if (( ${#changed[@]} > 0 )); then
    printf 'Changed signatures (%d):\n' "${#changed[@]}"
    for name in "${changed[@]}"; do
      printf '  - %s\n' "$name"
      printf '      old: %s\n' "${old_map[$name]}"
      printf '      new: %s\n' "${new_map[$name]}"
    done
  fi

  if (( ${#added[@]} > 0 )); then
    printf 'Added symbols (%d):\n' "${#added[@]}"
    printf '  - %s\n' "${added[@]}"
  fi

  if (( ${#removed[@]} > 0 || ${#changed[@]} > 0 )); then
    return 1
  fi

  return 0
}

if [[ "${1:-}" == "--compare" ]]; then
  shift
  compare_mode "$@"
  exit $?
fi

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <xgboost-install-include-dir> [xgboost-shared-lib-path]"
  echo "       $0 --compare <old-xgboost-include-dir> <new-xgboost-include-dir>"
  exit 2
fi

include_dir="$1"
shared_lib="${2:-}"
header="${include_dir}/xgboost/c_api.h"

if [[ ! -f "$header" ]]; then
  echo "XGBoost C API header not found: $header"
  exit 2
fi

mapfile -t used_symbols < <(
  grep -RhoE '\bXG[A-Za-z0-9_]+[[:space:]]*\(' c/exgboost/src/*.c \
    | sed -E 's/[[:space:]]*\($//' \
    | sort -u
)

missing_in_header=()
for symbol in "${used_symbols[@]}"; do
  if ! grep -qE "\\b${symbol}[[:space:]]*\\(" "$header"; then
    missing_in_header+=("$symbol")
  fi
done

if (( ${#missing_in_header[@]} > 0 )); then
  echo "Symbols used by exgboost NIF but missing from XGBoost C API header:"
  printf '  - %s\n' "${missing_in_header[@]}"
  exit 1
fi

if [[ -n "$shared_lib" && -f "$shared_lib" && "$(command -v nm || true)" != "" ]]; then
  declare -A exported_map=()

  if [[ "$(uname -s)" == "Darwin" ]]; then
    while IFS= read -r symbol; do
      [[ -n "$symbol" ]] && exported_map["$symbol"]=1
    done < <(nm -gU "$shared_lib" | awk '{print $3}' | sed 's/^_//' | sort -u)
  else
    while IFS= read -r symbol; do
      [[ -n "$symbol" ]] && exported_map["$symbol"]=1
    done < <(nm -D --defined-only "$shared_lib" | awk '{print $3}' | sort -u)
  fi

  missing_in_lib=()
  for symbol in "${used_symbols[@]}"; do
    if [[ -z "${exported_map[$symbol]+x}" ]]; then
      missing_in_lib+=("$symbol")
    fi
  done

  if (( ${#missing_in_lib[@]} > 0 )); then
    echo "Symbols declared in header but not exported by shared library:"
    printf '  - %s\n' "${missing_in_lib[@]}"
    exit 1
  fi
fi

echo "XGBoost C API compatibility check passed (${#used_symbols[@]} symbols)."
