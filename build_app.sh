#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$ROOT/build"
APP_NAME="SoundPilot"
BUNDLE="$BUILD_DIR/$APP_NAME.app"
EXECUTABLE_NAME="SoundPilot"
BUNDLE_ID="com.YOURNAME.SoundPilot"
SWIFT_SRC="$ROOT/client-swift"
RESOURCES="$SWIFT_SRC/SonyHeadphonesClient/Resources"
MDR_PKG="$ROOT/MDRProtocol"

# Parse flags
APPSTORE=false
SIGN_IDENTITY=""
for arg in "$@"; do
    case "$arg" in
        --appstore) APPSTORE=true ;;
        --sign=*) SIGN_IDENTITY="${arg#--sign=}" ;;
    esac
done

if $APPSTORE; then
    echo "==> Building for App Store"
fi

# Detect architecture
ARCH="$(uname -m)"
echo "==> Building for $ARCH"

# Step 1: Build MDRProtocol Swift Package
echo "==> Building MDRProtocol..."
swift build --package-path "$MDR_PKG" -c release --arch "$ARCH" 2>&1 | tail -1

# Create static library from .o files
MDR_BUILD="$MDR_PKG/.build/${ARCH}-apple-macosx/release"
ar rcs "$MDR_BUILD/libMDRProtocol.a" "$MDR_BUILD"/MDRProtocol.build/*.swift.o 2>/dev/null

# Step 2: Prepare app bundle
echo "==> Preparing bundle..."
mkdir -p "$BUILD_DIR"
rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS"
mkdir -p "$BUNDLE/Contents/Resources"

# Step 3: Compile Swift
echo "==> Compiling Swift..."
SWIFT_FILES=$(find "$SWIFT_SRC" -name '*.swift')

EXTRA_FLAGS=""
if $APPSTORE; then
    EXTRA_FLAGS="-D APPSTORE"
fi

swiftc -target "${ARCH}-apple-macosx14.0" -sdk "$(xcrun --show-sdk-path)" \
    -I "$MDR_BUILD/Modules" \
    -L "$MDR_BUILD" -lMDRProtocol \
    -framework SwiftUI -framework AppKit -framework CoreBluetooth -framework IOBluetooth \
    $EXTRA_FLAGS \
    -o "$BUNDLE/Contents/MacOS/$EXECUTABLE_NAME" \
    $SWIFT_FILES 2>&1 | grep -v "^ld: warning" || true

# Step 4: Info.plist (resolve Xcode variables)
echo "==> Writing Info.plist..."
sed -e "s/\$(EXECUTABLE_NAME)/$EXECUTABLE_NAME/g" \
    -e "s/\$(PRODUCT_BUNDLE_IDENTIFIER)/$BUNDLE_ID/g" \
    "$RESOURCES/Info.plist" > "$BUNDLE/Contents/Info.plist"

# Step 5: Icon
if [ -f "$RESOURCES/AppIcon.icns" ]; then
    cp "$RESOURCES/AppIcon.icns" "$BUNDLE/Contents/Resources/AppIcon.icns"
    echo "==> Icon copied"
fi

# Step 6: Code signing
if [ -n "$SIGN_IDENTITY" ]; then
    echo "==> Signing..."
    if $APPSTORE; then
        ENTITLEMENTS="$RESOURCES/SoundPilot.entitlements"
    else
        ENTITLEMENTS="$RESOURCES/SoundPilot-Direct.entitlements"
    fi
    codesign --force --options runtime \
        --sign "$SIGN_IDENTITY" \
        --entitlements "$ENTITLEMENTS" \
        "$BUNDLE"
    echo "==> Signed with: $SIGN_IDENTITY"
fi

# Step 7: Register with LaunchServices
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$BUNDLE" 2>/dev/null || true

echo ""
echo "==> Built: $BUNDLE"
echo "    Run:   open \"$BUNDLE\""
