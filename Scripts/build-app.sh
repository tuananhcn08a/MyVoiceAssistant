#!/bin/bash
set -euo pipefail

# Build MyVoiceAssistant.app bundle from Swift Package Manager executable
#
# Usage:
#   ./Scripts/build-app.sh                  # Ad-hoc codesign (default)
#   ./Scripts/build-app.sh --sign "Developer ID Application: Name (TEAMID)"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

APP_NAME="MyVoiceAssistant"
BUILD_DIR="$PROJECT_DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

SIGN_IDENTITY="-"  # Ad-hoc by default

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --sign)
            SIGN_IDENTITY="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--sign \"Developer ID Application: Name (TEAMID)\"]"
            exit 1
            ;;
    esac
done

echo "==> Building $APP_NAME (release)..."
cd "$PROJECT_DIR"
swift build -c release

# Find the built executable
EXECUTABLE=$(swift build -c release --show-bin-path)/$APP_NAME
if [ ! -f "$EXECUTABLE" ]; then
    echo "ERROR: Executable not found at $EXECUTABLE"
    exit 1
fi

echo "==> Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy executable
cp "$EXECUTABLE" "$MACOS_DIR/$APP_NAME"

# Copy Info.plist
cp "$PROJECT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

# Copy app icon if it exists
if [ -f "$PROJECT_DIR/Resources/AppIcon.icns" ]; then
    cp "$PROJECT_DIR/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

echo "==> Code signing ($SIGN_IDENTITY)..."
codesign --force --sign "$SIGN_IDENTITY" --deep "$APP_BUNDLE"

echo "==> Done!"
echo "    App bundle: $APP_BUNDLE"
echo "    Size: $(du -sh "$APP_BUNDLE" | cut -f1)"
echo ""
echo "    To install: cp -R \"$APP_BUNDLE\" /Applications/"
echo "    To run:     open \"$APP_BUNDLE\""
