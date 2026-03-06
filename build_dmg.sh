#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$ROOT/build"
APP_NAME="Sony Headphones"
BUNDLE="$BUILD_DIR/$APP_NAME.app"
VERSION=$(defaults read "$BUNDLE/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "2.0.0")
DMG_NAME="SonyHeadphones-${VERSION}.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"
DMG_RW="$BUILD_DIR/_rw.dmg"
STAGING="$BUILD_DIR/dmg-staging"
BG_IMG="$ROOT/client-swift/SonyHeadphonesClient/Resources/dmg-background.png"
BG_IMG_2X="$ROOT/client-swift/SonyHeadphonesClient/Resources/dmg-background@2x.png"
VOL_NAME="$APP_NAME"

WIN_W=660
WIN_H=400
ICON_SIZE=152
APP_X=190
APP_Y=195
APPS_X=468
APPS_Y=195

# Build the app first if not present
if [ ! -d "$BUNDLE" ]; then
    echo "==> App bundle not found, building first..."
    "$ROOT/build_app.sh"
fi

echo "==> Creating styled DMG ($DMG_NAME)..."

# Step 1: Prepare staging directory
rm -rf "$STAGING"
mkdir -p "$STAGING/.background"
cp -a "$BUNDLE" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
cp "$BG_IMG" "$STAGING/.background/background.png"
cp "$BG_IMG_2X" "$STAGING/.background/background@2x.png"

# Step 2: Create read-write DMG
rm -f "$DMG_RW" "$DMG_PATH"
hdiutil create \
    -volname "$VOL_NAME" \
    -srcfolder "$STAGING" \
    -ov \
    -format UDRW \
    -fs HFS+ \
    "$DMG_RW" > /dev/null

# Step 3: Mount and style with AppleScript
MOUNT_OUT=$(hdiutil attach -readwrite -noverify "$DMG_RW" | tail -1)
MOUNT_POINT=$(echo "$MOUNT_OUT" | awk -F'\t' '{print $NF}' | xargs)
DEVICE=$(echo "$MOUNT_OUT" | awk '{print $1}')

echo "==> Mounted at: $MOUNT_POINT"

# Apply Finder view settings
osascript <<APPLESCRIPT
tell application "Finder"
    tell disk "$VOL_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {100, 100, $((100 + WIN_W)), $((100 + WIN_H))}

        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to $ICON_SIZE
        set text size of theViewOptions to 14
        set label position of theViewOptions to bottom
        set background picture of theViewOptions to file ".background:background.png"

        set position of item "$APP_NAME.app" of container window to {$APP_X, $APP_Y}
        set position of item "Applications" of container window to {$APPS_X, $APPS_Y}

        close
        open
        update without registering applications
        delay 1
        close
    end tell
end tell
APPLESCRIPT

# Step 4: Set custom volume icon
if [ -f "$BUNDLE/Contents/Resources/AppIcon.icns" ]; then
    cp "$BUNDLE/Contents/Resources/AppIcon.icns" "$MOUNT_POINT/.VolumeIcon.icns"
    SetFile -c icnC "$MOUNT_POINT/.VolumeIcon.icns" 2>/dev/null || true
    SetFile -a C "$MOUNT_POINT" 2>/dev/null || true
fi

sync
hdiutil detach "$DEVICE" -quiet

# Step 5: Convert to compressed read-only DMG
hdiutil convert "$DMG_RW" -format UDZO -imagekey zlib-level=9 -o "$DMG_PATH" > /dev/null
rm -f "$DMG_RW"
rm -rf "$STAGING"

DMG_SIZE=$(du -h "$DMG_PATH" | cut -f1 | xargs)
echo ""
echo "==> DMG created: $DMG_PATH ($DMG_SIZE)"
