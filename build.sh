#!/bin/bash

# Build script for Scriptlet Runner
# Creates a release build and packages it as a DMG

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
DIST_DIR="$PROJECT_DIR/dist"
APP_NAME="Scriptlet Runner"
DMG_NAME="ScriptletRunner-1.0.0"

echo "Building Scriptlet Runner..."

# Clean previous builds
rm -rf "$BUILD_DIR"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# Build the app
xcodebuild -project "$PROJECT_DIR/ScriptletRunner.xcodeproj" \
    -scheme ScriptletRunner \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    -quiet

# Copy app to dist
cp -R "$BUILD_DIR/Build/Products/Release/$APP_NAME.app" "$DIST_DIR/"

echo "App built successfully: $DIST_DIR/$APP_NAME.app"

# Create DMG
echo "Creating DMG..."

DMG_TEMP="$BUILD_DIR/dmg_temp"
mkdir -p "$DMG_TEMP"

# Copy app to temp folder
cp -R "$DIST_DIR/$APP_NAME.app" "$DMG_TEMP/"

# Create Applications symlink
ln -s /Applications "$DMG_TEMP/Applications"

# Create the DMG
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_TEMP" \
    -ov \
    -format UDZO \
    "$DIST_DIR/$DMG_NAME.dmg"

# Cleanup
rm -rf "$DMG_TEMP"

echo ""
echo "Build complete!"
echo "  App: $DIST_DIR/$APP_NAME.app"
echo "  DMG: $DIST_DIR/$DMG_NAME.dmg"
