#!/bin/bash
# Builds SmokeBreak.app — release binary + bundle assembly + ad-hoc/dev signing.
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="SmokeBreak"
APP_DIR="$APP_NAME.app"
SIGN_IDENTITY="${SIGN_IDENTITY:--}"   # pass SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" to use your Apple dev cert

echo "Building release binary..."
swift build -c release

BIN_PATH=".build/release/$APP_NAME"

echo "Assembling $APP_DIR ..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

cp "$BIN_PATH" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "Info.plist" "$APP_DIR/Contents/Info.plist"

# SPM bundles resources into <binary>_SmokeBreak.bundle next to the binary
RES_BUNDLE=".build/release/${APP_NAME}_${APP_NAME}.bundle"
if [ -d "$RES_BUNDLE" ]; then
    cp -R "$RES_BUNDLE/." "$APP_DIR/Contents/Resources/"
fi
# also copy raw resources directly so Bundle.main lookups by name succeed
cp Resources/*.svg Resources/*.gif "$APP_DIR/Contents/Resources/" 2>/dev/null || true

echo "Signing ($SIGN_IDENTITY) ..."
codesign --force --deep --options runtime \
    --entitlements "SmokeBreak.entitlements" \
    --sign "$SIGN_IDENTITY" "$APP_DIR"

echo "Registering with Launch Services ..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$PWD/$APP_DIR"

echo "Done: $PWD/$APP_DIR"
echo "Test trigger:"
echo "  open 'smokebreak://break?cli=claude&duration=1&reason=test'"
