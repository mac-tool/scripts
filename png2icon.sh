#!/usr/bin/env bash

: '

### README

chmod +x png2icon.sh

./png2icon.sh \
  ./my-logo.png \
  ~/My Project/Demo-app/Resources/AppIcon.icns

NOTE: png file must be square size

'

set -euo pipefail

usage() {
  echo "Usage: png2icon <PNG image path> <target app/file/folder path>" >&2
}

if [ "$#" -ne 2 ]; then
  usage
  exit 1
fi

for cmd in sips iconutil osascript awk mktemp; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: required command not found: $cmd" >&2
    exit 1
  fi
done

abspath() {
  local path="$1"
  local dir
  local base

  if [ -d "$path" ]; then
    (
      cd -P -- "$path"
      pwd
    )
  else
    dir=$(dirname -- "$path")
    base=$(basename -- "$path")
    (
      cd -P -- "$dir"
      printf '%s/%s\n' "$PWD" "$base"
    )
  fi
}

RAW_PNG_PATH="$1"
RAW_TARGET_PATH="$2"

if [ ! -f "$RAW_PNG_PATH" ]; then
  echo "Error: PNG file not found: $RAW_PNG_PATH" >&2
  exit 1
fi

if [ ! -e "$RAW_TARGET_PATH" ] && [[ "$RAW_TARGET_PATH" != *.icns ]]; then
  echo "Error: target path not found: $RAW_TARGET_PATH" >&2
  exit 1
fi

# Resolve to absolute paths without relying on GNU-only `readlink -f`.
PNG_PATH=$(abspath "$RAW_PNG_PATH")

# Special handling: If the target is a .icns file and does not exist yet, create the parent directory first to help abspath work.
TARGET_DIR=$(dirname -- "$RAW_TARGET_PATH")
mkdir -p "$TARGET_DIR"
TARGET_PATH=$(abspath "$RAW_TARGET_PATH")

# Validate that the input is actually a PNG.
FORMAT=$(sips -g format "$PNG_PATH" 2>/dev/null | awk '/format:/ {print $2}')

if [ "$FORMAT" != "png" ]; then
  echo "Error: input must be a PNG; got: ${FORMAT:-unknown}" >&2
  exit 1
fi

# Validate dimensions.
WIDTH=$(sips -g pixelWidth "$PNG_PATH" 2>/dev/null | awk '/pixelWidth:/ {print $2}')
HEIGHT=$(sips -g pixelHeight "$PNG_PATH" 2>/dev/null | awk '/pixelHeight:/ {print $2}')

if [ -z "$WIDTH" ] || [ -z "$HEIGHT" ]; then
  echo "Error: could not determine PNG dimensions." >&2
  exit 1
fi

if [ "$WIDTH" != "$HEIGHT" ]; then
  echo "Error: PNG must be square; got ${WIDTH}x${HEIGHT}." >&2
  exit 1
fi

if [ "$WIDTH" -lt 1024 ] || [ "$HEIGHT" -lt 1024 ]; then
  echo "Warning: source is smaller than 1024x1024; resulting icon may look blurry." >&2
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

ICONSET_DIR="$TMP_DIR/AppIcon.iconset"
ICNS_PATH="$TMP_DIR/AppIcon.icns"

mkdir -p "$ICONSET_DIR"

echo "1/3: Generating icon sizes..."

sips -z 16 16     "$PNG_PATH" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
sips -z 32 32     "$PNG_PATH" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
sips -z 32 32     "$PNG_PATH" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
sips -z 64 64     "$PNG_PATH" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
sips -z 128 128   "$PNG_PATH" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
sips -z 256 256   "$PNG_PATH" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
sips -z 256 256   "$PNG_PATH" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
sips -z 512 512   "$PNG_PATH" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
sips -z 512 512   "$PNG_PATH" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
sips -z 1024 1024 "$PNG_PATH" --out "$ICONSET_DIR/icon_512x512@2x.png" >/dev/null

echo "2/3: Creating ICNS..."

iconutil -c icns "$ICONSET_DIR" -o "$ICNS_PATH"

echo "3/3: Applying icon..."

# Determine if the target is a .icns file
if [[ "$TARGET_PATH" == *.icns ]]; then
  echo "Detected target is a .icns file, directly overwriting destination..."
  cp -f "$ICNS_PATH" "$TARGET_PATH"
else
  # The target is an App or folder, use AppleScript to set a custom appearance icon
  osascript - "$ICNS_PATH" "$TARGET_PATH" <<'APPLESCRIPT'
use AppleScript version "2.4"
use framework "Cocoa"
use scripting additions

on run argv
  set imagePath to item 1 of argv
  set targetPath to item 2 of argv

  set imageData to current application's NSImage's alloc()'s initWithContentsOfFile:imagePath
  if imageData is missing value then error "Could not load icon image from temporary directory."

  set ok to current application's NSWorkspace's sharedWorkspace()'s setIcon:imageData forFile:targetPath options:0
  if ok as boolean is false then error "Failed to write custom icon metadata to target path."
end run
APPLESCRIPT

  # Force Finder to notice the metadata change.
  touch "$TARGET_PATH"

  osascript - "$TARGET_PATH" <<'APPLESCRIPT' >/dev/null 2>&1 || true
on run argv
  tell application "Finder" to update item (POSIX file (item 1 of argv) as alias)
end run
APPLESCRIPT
fi

echo "Success: icon changed."
