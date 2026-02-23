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
#   5. Creates DMG with Applications symlink
#   6. Signs DMG with Sparkle EdDSA key
#   7. Generates appcast.xml
#   8. Creates GitHub release with DMG + appcast
#
# Prerequisites:
#   - xcodegen, gh CLI installed
#   - Sparkle EdDSA key in Keychain (run generate_keys once)
#   - Logged into gh (gh auth login)
# ─────────────────────────────────────────────────────────────

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$REPO_ROOT/build"
PROJECT_YML="$REPO_ROOT/project.yml"
ENTITLEMENTS="$REPO_ROOT/CutCopyPaste/Resources/CutCopyPaste.entitlements"
REPO="chesspatzer/CutCopyPaste"

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

# ── Find Sparkle tools ──

SPARKLE_BIN="$(find ~/Library/Developer/Xcode/DerivedData -path "*/artifacts/sparkle/Sparkle/bin" -type d 2>/dev/null | head -1)"
if [ -z "$SPARKLE_BIN" ]; then
    echo "Error: Sparkle tools not found in DerivedData. Build the project first."
    exit 1
fi

echo "Using Sparkle tools: $SPARKLE_BIN"

# ── Step 1: Bump version ──

echo ""
echo "==> Bumping version to $VERSION..."

# Get current build number and increment
CURRENT_BUILD=$(grep 'CURRENT_PROJECT_VERSION:' "$PROJECT_YML" | sed 's/.*: *"\{0,1\}\([0-9]*\)"\{0,1\}/\1/')
NEW_BUILD=$((CURRENT_BUILD + 1))

sed -i '' "s/MARKETING_VERSION: \".*\"/MARKETING_VERSION: \"$VERSION\"/" "$PROJECT_YML"
sed -i '' "s/CURRENT_PROJECT_VERSION: \".*\"/CURRENT_PROJECT_VERSION: \"$NEW_BUILD\"/" "$PROJECT_YML"

echo "   Version: $VERSION (build $NEW_BUILD)"

# ── Step 2: Regenerate Xcode project ──

echo ""
echo "==> Regenerating Xcode project..."
cd "$REPO_ROOT"
xcodegen generate 2>&1 | grep -v "^$"

# ── Step 3: Fix entitlements (XcodeGen reverts them) ──

echo ""
echo "==> Fixing entitlements..."
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
echo "==> Archiving (Release)..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

xcodebuild -scheme CutCopyPaste -configuration Release \
    archive -archivePath "$BUILD_DIR/CutCopyPaste.xcarchive" \
    2>&1 | grep -E "(ARCHIVE SUCCEEDED|ARCHIVE FAILED|error:)"

if [ ! -d "$BUILD_DIR/CutCopyPaste.xcarchive" ]; then
    echo "Error: Archive failed."
    exit 1
fi

# ── Step 5: Create DMG ──

echo ""
echo "==> Creating DMG..."
DMG_STAGING="$BUILD_DIR/dmg_staging"
rm -rf "$DMG_STAGING"
mkdir -p "$DMG_STAGING"

cp -R "$BUILD_DIR/CutCopyPaste.xcarchive/Products/Applications/CutCopyPaste.app" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

hdiutil create -volname "CutCopyPaste" \
    -srcfolder "$DMG_STAGING" \
    -ov -format UDZO \
    "$BUILD_DIR/CutCopyPaste.dmg" 2>&1 | grep "created:"

# ── Step 6: Sign DMG ──

echo ""
echo "==> Signing DMG with Sparkle EdDSA key..."
SIGN_OUTPUT=$("$SPARKLE_BIN/sign_update" "$BUILD_DIR/CutCopyPaste.dmg" 2>&1)
echo "   $SIGN_OUTPUT"

# ── Step 7: Generate appcast ──

echo ""
echo "==> Generating appcast.xml..."
RELEASE_DIR="$BUILD_DIR/release"
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"
cp "$BUILD_DIR/CutCopyPaste.dmg" "$RELEASE_DIR/"

"$SPARKLE_BIN/generate_appcast" "$RELEASE_DIR" \
    --download-url-prefix "https://github.com/$REPO/releases/download/$TAG/" \
    2>&1

echo "   Appcast generated."

# ── Step 8: Create GitHub release ──

echo ""
echo "==> Creating GitHub release $TAG..."

gh release create "$TAG" \
    "$RELEASE_DIR/CutCopyPaste.dmg" \
    "$RELEASE_DIR/appcast.xml" \
    --title "$TAG" \
    --notes "$NOTES" \
    --repo "$REPO"

echo ""
echo "==> Done! Release $TAG published."
echo "   https://github.com/$REPO/releases/tag/$TAG"
