#!/bin/bash
# Builds SmokeBreak.app — release binary + bundle assembly + signing + optional notarization.
#
# Usage:
#   ./build_app.sh                                            # ad-hoc sign (local use only)
#   SIGN_IDENTITY="Developer ID Application: You (TEAMID)" ./build_app.sh
#   SIGN_IDENTITY="..." NOTARY_PROFILE="your-keychain-profile" ./build_app.sh   # also notarize + staple
#
# NOTARY_PROFILE refers to credentials stored once via:
#   xcrun notarytool store-credentials "your-keychain-profile" \
#     --apple-id "you@example.com" --team-id "TEAMID" --password "app-specific-password"
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="SmokeBreak"
APP_DIR="$APP_NAME.app"
ZIP_PATH="$APP_NAME.zip"
SIGN_IDENTITY="${SIGN_IDENTITY:--}"   # pass SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" to use your Apple dev cert
NOTARY_PROFILE="${NOTARY_PROFILE:-}"  # set to notarize + staple after signing (requires Developer ID identity)

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

if [ -n "$NOTARY_PROFILE" ]; then
    echo "Notarizing (profile: $NOTARY_PROFILE) ..."
    rm -f "$ZIP_PATH"
    ditto -c -k --keepParent "$APP_DIR" "$ZIP_PATH"
    xcrun notarytool submit "$ZIP_PATH" --keychain-profile "$NOTARY_PROFILE" --wait

    echo "Stapling ticket ..."
    xcrun stapler staple "$APP_DIR"
    xcrun stapler validate "$APP_DIR"

    echo "Repackaging stapled app ..."
    rm -f "$ZIP_PATH"
    ditto -c -k --keepParent "$APP_DIR" "$ZIP_PATH"

    echo "Gatekeeper check:"
    spctl -a -vvv -t install "$APP_DIR" || true
fi

echo "Registering with Launch Services ..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$PWD/$APP_DIR"

echo "Done: $PWD/$APP_DIR"
echo "Test trigger:"
echo "  open 'smokebreak://break?cli=claude&duration=1&reason=test'"
