#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
# CutCopyPaste Release Script
#
# Usage:
#   ./scripts/release.sh 1.1.0 "Release notes here"
#   ./scripts/release.sh 1.1.0              # prompts for notes
#
# What it does:
#   1. Bumps version in project.yml
#   2. Regenerates Xcode project (xcodegen)
#   3. Fixes entitlements (XcodeGen reverts them)
#   4. Archives in Release configuration
#   5. Code signs with Developer ID (if available)
#   6. Notarizes with Apple (if Developer ID present)
#   7. Creates DMG with Applications symlink
#   8. Signs DMG with codesign + Sparkle EdDSA key
#   9. Generates appcast.xml
#  10. Creates GitHub release with DMG + appcast
#
# Prerequisites:
#   - xcodegen, gh CLI installed
#   - Sparkle EdDSA key in Keychain (run generate_keys once)
#   - Logged into gh (gh auth login)
#   - (Optional) Developer ID Application certificate for signing
#   - (Optional) App-specific password stored as:
#       xcrun notarytool store-credentials "CutCopyPaste"
# ─────────────────────────────────────────────────────────────

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$REPO_ROOT/build"
PROJECT_YML="$REPO_ROOT/project.yml"
ENTITLEMENTS="$REPO_ROOT/CutCopyPaste/Resources/CutCopyPaste.entitlements"
REPO="chesspatzer/CutCopyPaste"
APP_NAME="CutCopyPaste"
BUNDLE_ID="com.cutcopypaste.app"
NOTARY_PROFILE="CutCopyPaste"

# ── Args ──

VERSION="${1:-}"
NOTES="${2:-}"

if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version> [release-notes]"
    echo "Example: $0 1.1.0 \"Add new feature X\""
    exit 1
fi

if [ -z "$NOTES" ]; then
    echo -n "Release notes (one line): "
    read -r NOTES
fi

TAG="v$VERSION"

# ── Detect signing identity ──

DEVELOPER_ID=""
if security find-identity -v -p codesigning 2>/dev/null | grep -q "Developer ID Application"; then
    DEVELOPER_ID=$(security find-identity -v -p codesigning 2>/dev/null | grep "Developer ID Application" | head -1 | sed 's/.*"\(.*\)"/\1/')
    echo "Found signing identity: $DEVELOPER_ID"
else
    echo "WARNING: No Developer ID certificate found."
    echo "         The app will be ad-hoc signed. Users must right-click > Open on first launch."
    echo ""
fi

# ── Detect notarytool credentials ──

CAN_NOTARIZE=false
if [ -n "$DEVELOPER_ID" ] && xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" 2>/dev/null | head -1 | grep -qv "Error"; then
    CAN_NOTARIZE=true
    echo "Notarization credentials found (profile: $NOTARY_PROFILE)"
else
    if [ -n "$DEVELOPER_ID" ]; then
        echo "WARNING: Notarization credentials not found."
        echo "         Run: xcrun notarytool store-credentials \"$NOTARY_PROFILE\""
        echo "         The app will be signed but NOT notarized."
        echo ""
    fi
fi

# ── Find Sparkle tools ──

SPARKLE_BIN="$(find ~/Library/Developer/Xcode/DerivedData -path "*/artifacts/sparkle/Sparkle/bin" -type d 2>/dev/null | head -1)"
if [ -z "$SPARKLE_BIN" ]; then
    echo "Error: Sparkle tools not found in DerivedData. Build the project first."
    exit 1
fi

echo "Using Sparkle tools: $SPARKLE_BIN"

# ── Step 1: Bump version ──

echo ""
echo "==> Step 1/9: Bumping version to $VERSION..."

# Get current build number and increment
CURRENT_BUILD=$(grep 'CURRENT_PROJECT_VERSION:' "$PROJECT_YML" | sed 's/.*: *"\{0,1\}\([0-9]*\)"\{0,1\}/\1/')
NEW_BUILD=$((CURRENT_BUILD + 1))

sed -i '' "s/MARKETING_VERSION: \".*\"/MARKETING_VERSION: \"$VERSION\"/" "$PROJECT_YML"
sed -i '' "s/CURRENT_PROJECT_VERSION: \".*\"/CURRENT_PROJECT_VERSION: \"$NEW_BUILD\"/" "$PROJECT_YML"

echo "   Version: $VERSION (build $NEW_BUILD)"

# ── Step 2: Regenerate Xcode project ──

echo ""
echo "==> Step 2/9: Regenerating Xcode project..."
cd "$REPO_ROOT"
xcodegen generate 2>&1 | grep -v "^$"

# ── Step 3: Fix entitlements (XcodeGen reverts them) ──

echo ""
echo "==> Step 3/9: Fixing entitlements..."
cat > "$ENTITLEMENTS" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.network.client</key>
	<true/>
</dict>
</plist>
PLIST

# ── Step 4: Archive ──

echo ""
echo "==> Step 4/9: Archiving (Release)..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"
APP_PATH="$ARCHIVE_PATH/Products/Applications/$APP_NAME.app"

xcodebuild -scheme CutCopyPaste -configuration Release \
    archive -archivePath "$ARCHIVE_PATH" \
    2>&1 | grep -E "(ARCHIVE SUCCEEDED|ARCHIVE FAILED|error:)"

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo "Error: Archive failed."
    exit 1
fi

# ── Step 5: Code sign ──

echo ""
echo "==> Step 5/9: Code signing..."

if [ -n "$DEVELOPER_ID" ]; then
    # Sign all frameworks first, then the app
    find "$APP_PATH/Contents/Frameworks" -name "*.framework" -o -name "*.dylib" 2>/dev/null | while read -r framework; do
        codesign --force --options runtime --sign "$DEVELOPER_ID" \
            --entitlements "$ENTITLEMENTS" \
            "$framework" 2>/dev/null || true
    done

    # Sign the Sparkle XPC services
    find "$APP_PATH" -name "*.xpc" -type d 2>/dev/null | while read -r xpc; do
        codesign --force --options runtime --sign "$DEVELOPER_ID" "$xpc" 2>/dev/null || true
    done

    # Sign helper apps inside Sparkle
    find "$APP_PATH" -name "*.app" -not -path "$APP_PATH" -type d 2>/dev/null | while read -r helper; do
        codesign --force --options runtime --sign "$DEVELOPER_ID" "$helper" 2>/dev/null || true
    done

    # Sign the main app
    codesign --force --options runtime --sign "$DEVELOPER_ID" \
        --entitlements "$ENTITLEMENTS" \
        "$APP_PATH"

    echo "   Signed with: $DEVELOPER_ID"
    codesign -dv "$APP_PATH" 2>&1 | grep -E "(Authority|TeamIdentifier)" | sed 's/^/   /'
else
    echo "   Skipping (no Developer ID). App is ad-hoc signed from archive."
fi

# ── Step 6: Notarize ──

echo ""
echo "==> Step 6/9: Notarization..."

if [ "$CAN_NOTARIZE" = true ]; then
    # Create a zip for notarization (notarytool requires zip or dmg)
    NOTARIZE_ZIP="$BUILD_DIR/$APP_NAME-notarize.zip"
    ditto -c -k --keepParent "$APP_PATH" "$NOTARIZE_ZIP"

    echo "   Submitting to Apple for notarization..."
    xcrun notarytool submit "$NOTARIZE_ZIP" \
        --keychain-profile "$NOTARY_PROFILE" \
        --wait 2>&1 | sed 's/^/   /'

    # Staple the notarization ticket to the app
    echo "   Stapling ticket..."
    xcrun stapler staple "$APP_PATH" 2>&1 | sed 's/^/   /'

    rm -f "$NOTARIZE_ZIP"
    echo "   Notarization complete."
else
    echo "   Skipping (no credentials). App will not be notarized."
fi

# ── Step 7: Create DMG ──

echo ""
echo "==> Step 7/9: Creating DMG..."
DMG_STAGING="$BUILD_DIR/dmg_staging"
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"
rm -rf "$DMG_STAGING"
mkdir -p "$DMG_STAGING"

cp -R "$APP_PATH" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_STAGING" \
    -ov -format UDZO \
    "$DMG_PATH" 2>&1 | grep "created:"

# Sign the DMG itself if we have a Developer ID
if [ -n "$DEVELOPER_ID" ]; then
    codesign --force --sign "$DEVELOPER_ID" "$DMG_PATH"
    echo "   DMG signed with Developer ID."
fi

# ── Step 8: Sign DMG with Sparkle EdDSA ──

echo ""
echo "==> Step 8/9: Signing DMG with Sparkle EdDSA key..."
SIGN_OUTPUT=$("$SPARKLE_BIN/sign_update" "$DMG_PATH" 2>&1)
echo "   $SIGN_OUTPUT"

# ── Step 9: Generate appcast + GitHub release ──

echo ""
echo "==> Step 9/9: Generating appcast & creating GitHub release..."
RELEASE_DIR="$BUILD_DIR/release"
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"
cp "$DMG_PATH" "$RELEASE_DIR/"

"$SPARKLE_BIN/generate_appcast" "$RELEASE_DIR" \
    --download-url-prefix "https://github.com/$REPO/releases/download/$TAG/" \
    2>&1

echo "   Appcast generated."

echo ""
echo "==> Creating GitHub release $TAG..."

gh release create "$TAG" \
    "$RELEASE_DIR/$APP_NAME.dmg" \
    "$RELEASE_DIR/appcast.xml" \
    --title "$TAG" \
    --notes "$NOTES" \
    --repo "$REPO"

# ── Summary ──

echo ""
echo "════════════════════════════════════════════════════"
echo "  Release $TAG published!"
echo "  https://github.com/$REPO/releases/tag/$TAG"
echo ""
if [ -n "$DEVELOPER_ID" ]; then
    if [ "$CAN_NOTARIZE" = true ]; then
        echo "  Signed + Notarized — opens seamlessly on any Mac"
    else
        echo "  Signed (not notarized) — users see 'Open' dialog on first launch"
    fi
else
    echo "  Ad-hoc signed — users must right-click > Open on first launch"
fi
echo "════════════════════════════════════════════════════"
