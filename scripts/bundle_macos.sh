#!/usr/bin/env bash
set -euo pipefail
priv=$1
library="$priv/lib/libxgboost.dylib"
# Upstream already uses @loader_path on recent versions. Resolve either layout.
while IFS= read -r dep; do
  case "$dep" in
    */libomp.dylib)
      source="$dep"
      if [[ "$source" == @* ]]; then
        source="$(brew --prefix libomp)/lib/libomp.dylib"
      fi
      rm -f "$priv/lib/libomp.dylib"
      cp "$source" "$priv/lib/libomp.dylib"
      chmod u+w "$priv/lib/libomp.dylib"
      install_name_tool -change "$dep" @loader_path/libomp.dylib "$library"
      # Include the runtime license with the redistributed binary.
      license="$(brew --prefix libomp)/share/doc/libomp/LICENSE.TXT"
      if [[ ! -f "$license" ]]; then
        license="$(brew --prefix libomp)/LICENSE.TXT"
      fi
      if [[ ! -f "$license" ]]; then
        echo "OpenMP license not found: $license" >&2
        exit 1
      fi
      cp "$license" "$priv/licenses/OpenMP-LICENSE.txt"
      ;;
  esac
done < <(otool -L "$library" | tail -n +2 | awk '{print $1}')

codesign --force --sign - "$library"
