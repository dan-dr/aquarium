#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${VERSION:-0.1.0}"
ARCH="$(uname -m)"
ARCHIVE="$ROOT_DIR/dist/Aquarium-$VERSION-$ARCH.zip"

VERSION="$VERSION" "$ROOT_DIR/script/package_app.sh" release >/dev/null

if [[ -e "$ARCHIVE" ]]; then
  if command -v trash >/dev/null 2>&1; then
    trash "$ARCHIVE"
  else
    mv "$ARCHIVE" "${TMPDIR:-/tmp}/$(basename "$ARCHIVE").old.$RANDOM"
  fi
fi

ditto -c -k --sequesterRsrc --keepParent \
  "$ROOT_DIR/dist/Aquarium.app" "$ARCHIVE"
shasum -a 256 "$ARCHIVE"
