#!/bin/bash
# Build and run QuicPair Mac app

set -euo pipefail

echo "=== Building QuicPair Mac App ==="

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "Error: Xcode is not installed"
    echo "Please install Xcode from the Mac App Store"
    exit 1
fi

# Build the server binary first
echo "Building server binary..."
cd ../server
go build -o ../mac-app/QuicPair/Resources/quicpair-server
cd ../mac-app

# Copy branding assets
echo "Copying assets..."
mkdir -p QuicPair/Resources
cp -r ../quicpair_branding_pack/branding/appicon/AppIcon.appiconset QuicPair/Resources/

# Build the Mac app
echo "Building Mac app..."
xcodebuild -project QuicPair.xcodeproj \
           -scheme QuicPair \
           -configuration Release \
           -derivedDataPath build \
           clean build

# Find the built app
APP_PATH=$(find build -name "QuicPair.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
    echo "Error: Could not find built app"
    exit 1
fi

echo "✅ Build successful!"
echo "App location: $APP_PATH"

# Ask if user wants to run the app
read -p "Do you want to run QuicPair now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open "$APP_PATH"
fi

# Create DMG for distribution
read -p "Create DMG installer? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Creating DMG..."
    
    # Create a temporary directory for DMG contents
    DMG_DIR=$(mktemp -d)
    cp -R "$APP_PATH" "$DMG_DIR/"
    
    # Create symlink to Applications
    ln -s /Applications "$DMG_DIR/Applications"
    
    # Create DMG
    hdiutil create -volname "QuicPair" \
                   -srcfolder "$DMG_DIR" \
                   -ov \
                   -format UDZO \
                   "QuicPair-mac-latest.dmg"
    
    # Clean up
    rm -rf "$DMG_DIR"
    
    echo "✅ DMG created: QuicPair-mac-latest.dmg"
    
    # Copy to website downloads if exists
    if [ -d "../website/downloads" ]; then
        cp QuicPair-mac-latest.dmg ../website/downloads/
        echo "✅ Copied to website downloads"
    fi
fi