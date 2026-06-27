#!/bin/bash
#
# Build Atoll from source and replace the installed /Applications/Atoll.app.
# Requires the full Xcode (not just Command Line Tools).
#
# Usage:
#   ./build-and-replace.sh
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$REPO_DIR/DynamicIsland.xcodeproj"
SCHEME="DynamicIsland"
DERIVED="$REPO_DIR/.build-derived"
APP_NAME="Atoll.app"
INSTALL_PATH="/Applications/$APP_NAME"

echo "==> Checking for full Xcode..."
if ! xcodebuild -version >/dev/null 2>&1; then
  echo "ERROR: xcodebuild not available. Install full Xcode from the App Store, then run:"
  echo "       sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
  exit 1
fi
xcodebuild -version

echo "==> Building $SCHEME (Release, ad-hoc signed)..."
rm -rf "$DERIVED"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -derivedDataPath "$DERIVED" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM="" \
  -destination 'generic/platform=macOS' \
  clean build

BUILT_APP="$DERIVED/Build/Products/Release/$APP_NAME"
if [ ! -d "$BUILT_APP" ]; then
  echo "ERROR: build did not produce $BUILT_APP"
  echo "Look for the .app under $DERIVED/Build/Products/"
  exit 1
fi
echo "==> Built: $BUILT_APP"

echo "==> Quitting running Atoll (if any)..."
osascript -e 'tell application "Atoll" to quit' >/dev/null 2>&1 || true
pkill -x Atoll >/dev/null 2>&1 || true
sleep 1

echo "==> Replacing $INSTALL_PATH ..."
if [ -d "$INSTALL_PATH" ]; then
  rm -rf "$INSTALL_PATH"
fi
cp -R "$BUILT_APP" "$INSTALL_PATH"

# Remove quarantine so it launches without Gatekeeper nagging.
xattr -dr com.apple.quarantine "$INSTALL_PATH" 2>/dev/null || true

echo "==> Done. Launching Atoll..."
open "$INSTALL_PATH"
echo "    Installed: $INSTALL_PATH"
