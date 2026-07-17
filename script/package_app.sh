#!/usr/bin/env bash
set -euo pipefail

CONFIGURATION="${1:-release}"
APP_NAME="Aquarium"
BUNDLE_ID="com.danrosenshain.Aquarium"
VERSION="${VERSION:-0.1.0}"
MIN_SYSTEM_VERSION="14.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RESOURCES_DIR="$CONTENTS/Resources"
INFO_PLIST="$CONTENTS/Info.plist"

discard_path() {
  local path="$1"
  [[ -e "$path" ]] || return 0
  if command -v trash >/dev/null 2>&1; then
    trash "$path"
  else
    mv "$path" "${TMPDIR:-/tmp}/$(basename "$path").old.$RANDOM"
  fi
}

cd "$ROOT_DIR"
swift build -c "$CONFIGURATION"
BUILD_BINARY="$(swift build -c "$CONFIGURATION" --show-bin-path)/$APP_NAME"

mkdir -p "$DIST_DIR"
discard_path "$APP_BUNDLE"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
ditto "$BUILD_BINARY" "$MACOS_DIR/$APP_NAME"
chmod 755 "$MACOS_DIR/$APP_NAME"

plutil -create xml1 "$INFO_PLIST"
plutil -insert CFBundleDisplayName -string "$APP_NAME" "$INFO_PLIST"
plutil -insert CFBundleExecutable -string "$APP_NAME" "$INFO_PLIST"
plutil -insert CFBundleIconFile -string "$APP_NAME" "$INFO_PLIST"
plutil -insert CFBundleIdentifier -string "$BUNDLE_ID" "$INFO_PLIST"
plutil -insert CFBundleInfoDictionaryVersion -string "6.0" "$INFO_PLIST"
plutil -insert CFBundleName -string "$APP_NAME" "$INFO_PLIST"
plutil -insert CFBundlePackageType -string "APPL" "$INFO_PLIST"
plutil -insert CFBundleShortVersionString -string "$VERSION" "$INFO_PLIST"
plutil -insert CFBundleVersion -string "1" "$INFO_PLIST"
plutil -insert LSMinimumSystemVersion -string "$MIN_SYSTEM_VERSION" "$INFO_PLIST"
plutil -insert LSUIElement -bool true "$INFO_PLIST"
plutil -insert NSPrincipalClass -string "NSApplication" "$INFO_PLIST"

ICON_WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/aquarium-icon.XXXXXX")"
ICONSET="$ICON_WORK_DIR/$APP_NAME.iconset"
mkdir -p "$ICONSET"
swift "$ROOT_DIR/script/generate_icon.swift" "$ICON_WORK_DIR/icon-1024.png"

while read -r points pixels suffix; do
  sips -z "$pixels" "$pixels" "$ICON_WORK_DIR/icon-1024.png" \
    --out "$ICONSET/icon_${points}x${points}${suffix}.png" >/dev/null
done <<'SIZES'
16 16
16 32 @2x
32 32
32 64 @2x
128 128
128 256 @2x
256 256
256 512 @2x
512 512
512 1024 @2x
SIZES

iconutil -c icns "$ICONSET" -o "$RESOURCES_DIR/$APP_NAME.icns"

if [[ -n "${CODESIGN_IDENTITY:-}" ]]; then
  codesign --force --options runtime --timestamp \
    --sign "$CODESIGN_IDENTITY" "$APP_BUNDLE"
else
  codesign --force --sign - --identifier "$BUNDLE_ID" \
    --requirements "=designated => identifier \"$BUNDLE_ID\"" \
    "$APP_BUNDLE"
fi

codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
echo "$APP_BUNDLE"
