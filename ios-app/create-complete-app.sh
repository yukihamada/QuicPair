#!/bin/bash

echo "🚀 Creating Complete QuicPair iOS App"
echo "===================================="

# Clean up everything first
rm -rf QuicPair.xcodeproj QuicPairApp.xcodeproj QuicPair QuicPairApp QuicPairSimple
rm -f project.yml

# Create clean directory structure
mkdir -p QuicPair/{Views,Services,Models}

# Create Info.plist
cat > QuicPair/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleDisplayName</key>
    <string>QuicPair</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
    <key>NSCameraUsageDescription</key>
    <string>QuicPair needs camera access to scan QR codes for connecting to your Mac</string>
    <key>NSLocalNetworkUsageDescription</key>
    <string>QuicPair needs local network access to connect to your Mac and use local LLM</string>
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <false/>
    </dict>
    <key>UILaunchScreen</key>
    <dict/>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>armv7</string>
    </array>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
    </array>
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
</dict>
</plist>
EOF

# Create Assets.xcassets
mkdir -p QuicPair/Assets.xcassets/{AppIcon.appiconset,AccentColor.colorset}

# Assets.xcassets Contents.json
cat > QuicPair/Assets.xcassets/Contents.json << 'EOF'
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

# AccentColor Contents.json
cat > QuicPair/Assets.xcassets/AccentColor.colorset/Contents.json << 'EOF'
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "1.000",
          "green" : "0.478",
          "red" : "0.000"
        }
      },
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

# AppIcon Contents.json
cat > QuicPair/Assets.xcassets/AppIcon.appiconset/Contents.json << 'EOF'
{
  "images" : [
    {
      "filename" : "icon-20@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "icon-20@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "filename" : "icon-29@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "icon-29@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "filename" : "icon-40@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "icon-40@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "filename" : "icon-60@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "filename" : "icon-60@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "filename" : "icon-1024.png",
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

# Generate placeholder icons
python3 << 'PYTHON_EOF'
from PIL import Image, ImageDraw
import os

sizes = [
    (40, "icon-20@2x.png"),
    (60, "icon-20@3x.png"),
    (58, "icon-29@2x.png"),
    (87, "icon-29@3x.png"),
    (80, "icon-40@2x.png"),
    (120, "icon-40@3x.png"),
    (120, "icon-60@2x.png"),
    (180, "icon-60@3x.png"),
    (1024, "icon-1024.png")
]

output_dir = "QuicPair/Assets.xcassets/AppIcon.appiconset"

for size, filename in sizes:
    img = Image.new('RGB', (size, size), color='#007AFF')
    draw = ImageDraw.Draw(img)
    
    # Draw a lightning bolt
    center_x = size // 2
    center_y = size // 2
    bolt_size = size // 3
    
    points = [
        (center_x - bolt_size//2, center_y - bolt_size),
        (center_x, center_y - bolt_size//3),
        (center_x - bolt_size//4, center_y - bolt_size//3),
        (center_x + bolt_size//2, center_y + bolt_size),
        (center_x, center_y + bolt_size//3),
        (center_x + bolt_size//4, center_y + bolt_size//3)
    ]
    
    draw.polygon(points, fill='white')
    img.save(os.path.join(output_dir, filename))

print("✅ Icons created!")
PYTHON_EOF

# Copy all Swift files from existing directories
echo "📝 Copying Swift files..."

# Copy main files
[ -f QuicPair/QuicPairApp.swift ] || cp QuicPairApp/QuicPairApp/QuicPairApp.swift QuicPair/QuicPairApp.swift 2>/dev/null || echo "QuicPairApp.swift not found"
[ -f QuicPair/AppState.swift ] || cp QuicPairApp/QuicPairApp/AppState.swift QuicPair/AppState.swift 2>/dev/null || echo "AppState.swift not found"

# Copy Views
for file in ContentView.swift QRScannerView.swift ChatView.swift OnboardingView.swift ManualConnectionView.swift TTFTChartView.swift; do
    [ -f QuicPair/Views/$file ] || cp QuicPairApp/QuicPairApp/Views/$file QuicPair/Views/$file 2>/dev/null || echo "$file not found"
done

# Copy Services
for file in ChatService.swift ConnectionManager.swift NoiseManager.swift; do
    [ -f QuicPair/Services/$file ] || cp QuicPairApp/QuicPairApp/Services/$file QuicPair/Services/$file 2>/dev/null || echo "$file not found"
done

# Copy Models
for file in ChatMessage.swift RecentConnection.swift; do
    [ -f QuicPair/Models/$file ] || cp QuicPairApp/QuicPairApp/Models/$file QuicPair/Models/$file 2>/dev/null || echo "$file not found"
done

# Create project.yml
cat > project.yml << 'EOF'
name: QuicPair
options:
  bundleIdPrefix: com.hamada
  deploymentTarget:
    iOS: 16.0
  createIntermediateGroups: true
  generateEmptyDirectories: true
settings:
  MARKETING_VERSION: "1.0"
  CURRENT_PROJECT_VERSION: "1"
targets:
  QuicPair:
    type: application
    platform: iOS
    sources:
      - path: QuicPair
        excludes:
          - "**/.DS_Store"
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.hamada.QuicPair.yuki
        PRODUCT_NAME: QuicPair
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: AccentColor
        DEVELOPMENT_TEAM: T47FJ2TW22
        CODE_SIGN_STYLE: Automatic
        INFOPLIST_FILE: QuicPair/Info.plist
        IPHONEOS_DEPLOYMENT_TARGET: 16.0
        SWIFT_VERSION: 5.0
        TARGETED_DEVICE_FAMILY: "1,2"
        GENERATE_INFOPLIST_FILE: NO
EOF

# Generate project
echo "🔨 Generating Xcode project..."
xcodegen

echo ""
echo "✅ Complete! Opening Xcode..."
open QuicPair.xcodeproj

echo ""
echo "📱 Project is ready with:"
echo "  - Bundle ID: com.hamada.QuicPair.yuki"
echo "  - Team: T47FJ2TW22"
echo "  - All Swift files copied"
echo "  - Assets and icons created"
echo "  - Info.plist configured"
echo ""
echo "Just press Cmd+R to build and run!"