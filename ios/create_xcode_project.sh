#!/bin/bash

# DreamEcho Xcode 项目创建脚本
# 自动创建完整的 Xcode 项目结构

set -e

echo "🚀 开始创建 DreamEcho Xcode 项目..."

# 项目配置
PROJECT_NAME="DreamEcho"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
XCODE_PROJECT_DIR="$PROJECT_DIR/$PROJECT_NAME"
BUNDLE_ID="com.dreamecho.app"

# 检查是否已存在项目
if [ -d "$XCODE_PROJECT_DIR" ]; then
    echo "⚠️  项目已存在: $XCODE_PROJECT_DIR"
    read -p "是否删除并重新创建? (y/N): " confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        rm -rf "$XCODE_PROJECT_DIR"
    else
        echo "❌ 取消创建"
        exit 1
    fi
fi

# 创建项目目录结构
echo "📁 创建项目目录..."
mkdir -p "$XCODE_PROJECT_DIR"
mkdir -p "$XCODE_PROJECT_DIR/$PROJECT_NAME"
mkdir -p "$XCODE_PROJECT_DIR/${PROJECT_NAME}Tests"
mkdir -p "$XCODE_PROJECT_DIR/$PROJECT_NAME/Preview Content"

# 复制源代码
echo "📋 复制源代码..."
cp -R "$PROJECT_DIR/DreamEchoApp/Sources/"* "$XCODE_PROJECT_DIR/$PROJECT_NAME/"

# 复制资源文件
echo "🎨 复制资源文件..."
if [ -d "$PROJECT_DIR/DreamEchoApp/Assets.xcassets" ]; then
    cp -R "$PROJECT_DIR/DreamEchoApp/Assets.xcassets" "$XCODE_PROJECT_DIR/$PROJECT_NAME/"
fi

# 创建 Info.plist
echo "⚙️  创建 Info.plist..."
cat > "$XCODE_PROJECT_DIR/$PROJECT_NAME/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundleDisplayName</key>
    <string>梦境回声</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>API_BASE_URL</key>
    <string>https://api.dreamecho.ai</string>
    <key>ENABLE_HAPTICS</key>
    <string>true</string>
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <true/>
    </dict>
    <key>UILaunchScreen</key>
    <dict/>
</dict>
</plist>
EOF

# 创建预览内容
cat > "$XCODE_PROJECT_DIR/$PROJECT_NAME/Preview Content/Preview Assets.xcassets/Contents.json" << 'EOF'
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

# 创建测试文件
echo "🧪 创建测试文件..."
cat > "$XCODE_PROJECT_DIR/${PROJECT_NAME}Tests/${PROJECT_NAME}Tests.swift" << 'EOF'
import XCTest
@testable import DreamEcho

final class DreamEchoTests: XCTestCase {
    func testExample() throws {
        // 基础测试
        XCTAssertTrue(true)
    }
}
EOF

# 创建 project.pbxproj（简化版）
echo "🔧 生成 Xcode 项目文件..."
cat > "$XCODE_PROJECT_DIR/generate_project.swift" << 'SWIFT'
import Foundation

// 使用 xcodegen 或手动创建
print("请在 Xcode 中打开此文件夹，然后选择 File > New > Project")
print("或运行: open \(FileManager.default.currentDirectoryPath)")
SWIFT

echo ""
echo "✅ 项目结构创建完成！"
echo ""
echo "📍 项目位置: $XCODE_PROJECT_DIR"
echo ""
echo "接下来的步骤："
echo ""
echo "1️⃣  打开 Xcode:"
echo "   open -a Xcode"
echo ""
echo "2️⃣  创建新项目:"
echo "   - File > New > Project"
echo "   - 选择 iOS > App"
echo "   - Product Name: DreamEcho"
echo "   - Bundle Identifier: $BUNDLE_ID"
echo "   - 保存到: $PROJECT_DIR"
echo ""
echo "3️⃣  删除默认文件并导入源代码:"
echo "   - 删除 ContentView.swift"
echo "   - 拖入 $XCODE_PROJECT_DIR/$PROJECT_NAME 文件夹中的所有文件"
echo ""
echo "4️⃣  连接设备并运行!"
echo ""
echo "💡 提示: 如果你有 xcodegen 工具，可以使用它自动生成项目文件"
echo ""

# 尝试自动打开 Xcode
read -p "是否立即打开 Xcode? (y/N): " open_xcode
if [ "$open_xcode" = "y" ] || [ "$open_xcode" = "Y" ]; then
    echo "🚀 正在打开 Xcode..."
    open -a Xcode
fi

echo ""
echo "📖 详细部署指南请参考: ios/部署指南.md"




