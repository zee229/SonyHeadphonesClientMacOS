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

# Detect architecture
ARCH="$(uname -m)"
echo "==> Building for $ARCH"

# Step 1: Build libmdr
echo "==> Building libmdr..."
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"
cmake "$ROOT" -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_OSX_ARCHITECTURES="$ARCH" > /dev/null
cmake --build . --target mdr mdr_PlatformMacOS -- -j"$(sysctl -n hw.logicalcpu)" 2>&1 | tail -1

# Step 2: Prepare app bundle
echo "==> Preparing bundle..."
rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS"
mkdir -p "$BUNDLE/Contents/Resources"

# Step 3: Compile Swift
echo "==> Compiling Swift..."
SWIFT_FILES=$(find "$SWIFT_SRC" -name '*.swift')

swiftc -target "${ARCH}-apple-macosx14.0" -sdk "$(xcrun --show-sdk-path)" \
    -import-objc-header "$SWIFT_SRC/SonyHeadphonesClient/Bridge/SonyHeadphonesClient-Bridging-Header.h" \
    -I "$ROOT/libmdr/include" \
    -L "$BUILD_DIR/libmdr/src" -L "$BUILD_DIR/libmdr/src/Platform/MacOS" -L "$BUILD_DIR/_deps/fmt-build" \
    -lmdr -lmdr_PlatformMacOS -lfmt -lstdc++ \
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
