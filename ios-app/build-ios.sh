#!/bin/bash
# Build QuicPair iOS app

set -euo pipefail

echo "=== Building QuicPair iOS App ==="

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "Error: Xcode is not installed"
    exit 1
fi

# Copy branding assets
echo "Copying assets..."
mkdir -p QuicPair/Resources
cp -r ../quicpair_branding_pack/branding/appicon/AppIcon.appiconset QuicPair/Resources/

# Check for WebRTC framework
if [ ! -d "WebRTC.xcframework" ]; then
    echo "WebRTC framework not found."
    echo "Please download from: https://github.com/stasel/WebRTC-iOS"
    echo "Or use Swift Package Manager to add WebRTC"
    exit 1
fi

# Build for simulator
echo "Building for iOS Simulator..."
xcodebuild -project QuicPair.xcodeproj \
           -scheme QuicPair \
           -configuration Debug \
           -sdk iphonesimulator \
           -derivedDataPath build \
           clean build

echo "✅ Build successful!"

# Ask if user wants to run in simulator
read -p "Run in iOS Simulator? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Find the app
    APP_PATH=$(find build -name "QuicPair.app" -type d | grep iphonesimulator | head -1)
    
    # Install and run in simulator
    xcrun simctl install booted "$APP_PATH"
    xcrun simctl launch booted com.quicpair.QuicPair
fi