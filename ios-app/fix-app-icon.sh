#!/bin/bash

echo "🎨 Fixing App Icon Issue"
echo "======================="

# AppIcon.appiconsetが正しい場所にあるか確認
PROJECT_DIR="QuicPairApp/QuicPairApp"

# Assets.xcassetsディレクトリを再作成
rm -rf "$PROJECT_DIR/Assets.xcassets"
mkdir -p "$PROJECT_DIR/Assets.xcassets/AppIcon.appiconset"
mkdir -p "$PROJECT_DIR/Assets.xcassets/AccentColor.colorset"

# Contents.jsonを作成
cat > "$PROJECT_DIR/Assets.xcassets/Contents.json" << 'EOF'
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

# AppIcon.appiconsetのContents.jsonを作成
cat > "$PROJECT_DIR/Assets.xcassets/AppIcon.appiconset/Contents.json" << 'EOF'
{
  "images" : [
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "20x20"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "40x40"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "76x76"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "76x76"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "83.5x83.5"
    },
    {
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

# AccentColor.colorsetのContents.jsonを作成
cat > "$PROJECT_DIR/Assets.xcassets/AccentColor.colorset/Contents.json" << 'EOF'
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

# 一時的なアイコン画像を生成（シンプルな青い四角）
echo "🎨 Creating placeholder app icon..."

# Python スクリプトでプレースホルダーアイコンを生成
python3 << 'EOF'
from PIL import Image, ImageDraw, ImageFont
import os

# アイコンサイズのリスト
sizes = [
    (40, "Icon-20@2x.png"),
    (60, "Icon-20@3x.png"),
    (58, "Icon-29@2x.png"),
    (87, "Icon-29@3x.png"),
    (80, "Icon-40@2x.png"),
    (120, "Icon-40@3x.png"),
    (120, "Icon-60@2x.png"),
    (180, "Icon-60@3x.png"),
    (20, "Icon-20.png"),
    (40, "Icon-20@2x~ipad.png"),
    (29, "Icon-29.png"),
    (58, "Icon-29@2x~ipad.png"),
    (40, "Icon-40~ipad.png"),
    (80, "Icon-40@2x~ipad.png"),
    (76, "Icon-76.png"),
    (152, "Icon-76@2x.png"),
    (167, "Icon-83.5@2x.png"),
    (1024, "Icon-1024.png")
]

output_dir = "QuicPairApp/QuicPairApp/Assets.xcassets/AppIcon.appiconset"

for size, filename in sizes:
    # 青いグラデーション背景
    img = Image.new('RGB', (size, size), color='#007AFF')
    draw = ImageDraw.Draw(img)
    
    # 中央に稲妻アイコンを描画（シンプルな形）
    center_x = size // 2
    center_y = size // 2
    bolt_size = size // 3
    
    # 稲妻の形を描画
    points = [
        (center_x - bolt_size//2, center_y - bolt_size),
        (center_x, center_y - bolt_size//3),
        (center_x - bolt_size//4, center_y - bolt_size//3),
        (center_x + bolt_size//2, center_y + bolt_size),
        (center_x, center_y + bolt_size//3),
        (center_x + bolt_size//4, center_y + bolt_size//3)
    ]
    
    draw.polygon(points, fill='white')
    
    # 保存
    img.save(os.path.join(output_dir, filename))

print("✅ Placeholder icons created!")
EOF

# Contents.jsonを更新してファイル名を追加
cat > "$PROJECT_DIR/Assets.xcassets/AppIcon.appiconset/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "Icon-20@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-20@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-29@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-29@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-40@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-40@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-60@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "filename" : "Icon-60@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "filename" : "Icon-20.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-20@2x~ipad.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-29.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-29@2x~ipad.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-40~ipad.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-40@2x~ipad.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-76.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "76x76"
    },
    {
      "filename" : "Icon-76@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "76x76"
    },
    {
      "filename" : "Icon-83.5@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "83.5x83.5"
    },
    {
      "filename" : "Icon-1024.png",
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

echo ""
echo "✅ App Icon issue fixed!"
echo ""
echo "🎯 Next steps:"
echo "1. Clean build folder (Shift+Cmd+K)"
echo "2. Build again (Cmd+B)"
echo ""
echo "Note: Placeholder icons have been created. You can replace them with actual icons later."