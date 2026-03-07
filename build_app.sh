#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$ROOT/build"
APP_NAME="Sony Headphones"
BUNDLE="$BUILD_DIR/$APP_NAME.app"
EXECUTABLE_NAME="SonyHeadphonesClient"
BUNDLE_ID="com.mos9527.SonyHeadphonesClient"
SWIFT_SRC="$ROOT/client-swift"
RESOURCES="$SWIFT_SRC/SonyHeadphonesClient/Resources"
MDR_PKG="$ROOT/MDRProtocol"

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

swiftc -target "${ARCH}-apple-macosx14.0" -sdk "$(xcrun --show-sdk-path)" \
    -I "$MDR_BUILD/Modules" \
    -L "$MDR_BUILD" -lMDRProtocol \
    -framework SwiftUI -framework AppKit -framework CoreBluetooth -framework IOBluetooth \
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

# Step 6: Register with LaunchServices
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$BUNDLE" 2>/dev/null || true

echo ""
echo "==> Built: $BUNDLE"
echo "    Run:   open \"$BUNDLE\""
