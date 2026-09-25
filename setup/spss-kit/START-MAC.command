#!/bin/sh
set -eu

kit_root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
anchor_path=$(printf '%s' "$kit_root" | sed "s/'/''/g")
anchor="CD '$anchor_path'."

for syntax in "$kit_root"/spss/*.sps; do
  [ -f "$syntax" ] || { echo 'No SPSS chapter files were found.' >&2; exit 1; }
  temporary="$syntax.tmp"
  if ! awk -v anchor="$anchor" '
    after_marker { print anchor; after_marker = 0; found++; next }
    { print; if ($0 == "* BOOKROOT-AUTO-CONFIGURED.") after_marker = 1 }
    END { if (found != 1) exit 2 }
  ' "$syntax" > "$temporary"; then
    rm -f "$temporary"
    echo "Could not find the path marker in $(basename "$syntax")." >&2
    exit 1
  fi
  mv "$temporary" "$syntax"
done

echo "Prepared the SPSS syntax files for this folder."
echo "In the setup check, choose Run All. Then open any chapter in spss/."
if [ "$(uname)" = "Darwin" ]; then
  open "$kit_root/spss/00-CHECK-SETUP.sps"
fi
