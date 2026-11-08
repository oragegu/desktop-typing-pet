#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h}"
BUILD_DIR="$ROOT_DIR/.build/apple/Products/Release"
APP_DIR="/private/tmp/typingpet-build-${UID}/Typing Pet.app"
CONTENTS_DIR="$APP_DIR/Contents"
SIGNING_IDENTITY="${TYPINGPET_SIGNING_IDENTITY:-}"
DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
export DEVELOPER_DIR
export CLANG_MODULE_CACHE_PATH="$ROOT_DIR/.build/clang-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$ROOT_DIR/.build/swiftpm-cache"

if [[ -z "$SIGNING_IDENTITY" ]]; then
    SIGNING_IDENTITY="$(security find-identity -p codesigning -v | awk '/"Apple Development:/{print $2; exit}')"
fi

if [[ -z "$SIGNING_IDENTITY" ]]; then
    echo "No Apple Development code-signing identity is available." >&2
    echo "Run ./script/setup_local_signing.sh for setup instructions." >&2
    exit 1
fi

cd "$ROOT_DIR"
swift build -c release --disable-sandbox --arch arm64 --arch x86_64

rm -rf "$APP_DIR"
mkdir -p "$CONTENTS_DIR/MacOS" "$CONTENTS_DIR/Resources/images"
cp "$BUILD_DIR/TypingPet" "$CONTENTS_DIR/MacOS/TypingPet"
cp "$ROOT_DIR"/images/*.png "$CONTENTS_DIR/Resources/images/"

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key><string>en</string>
    <key>CFBundleExecutable</key><string>TypingPet</string>
    <key>CFBundleIdentifier</key><string>com.typingpet.macos</string>
    <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
    <key>CFBundleName</key><string>Typing Pet</string>
    <key>CFBundleDisplayName</key><string>Typing Pet</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>NSPrincipalClass</key><string>NSApplication</string>
    <key>CFBundleShortVersionString</key><string>1.0.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/>
    <key>NSInputMonitoringUsageDescription</key><string>Typing Pet reacts visually when you press a key. It does not store or transmit keystrokes.</string>
</dict>
</plist>
PLIST

xattr -cr "$APP_DIR"
codesign --force --options runtime --sign "$SIGNING_IDENTITY" "$APP_DIR"
xattr -cr "$APP_DIR"
xattr -d com.apple.FinderInfo "$APP_DIR" 2>/dev/null || true
codesign --verify --deep --strict --verbose=2 "$APP_DIR"
echo "Built: $APP_DIR"
echo "Signed with: $SIGNING_IDENTITY"
