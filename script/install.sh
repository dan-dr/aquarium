#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_APP="$ROOT_DIR/dist/Aquarium.app"
TARGET_APP="/Applications/Aquarium.app"

"$ROOT_DIR/script/package_app.sh" release >/dev/null

if [[ -e "$TARGET_APP" ]]; then
  if command -v trash >/dev/null 2>&1; then
    trash "$TARGET_APP"
  else
    echo "$TARGET_APP already exists; move it to Trash first." >&2
    exit 1
  fi
fi

ditto "$SOURCE_APP" "$TARGET_APP"
open "$TARGET_APP"
