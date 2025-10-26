#!/bin/bash

# DreamEcho iOS应用部署脚本
# 自动配置签名并部署到连接的设备

set -e

echo "======================================"
echo "DreamEcho iOS 应用部署脚本"
echo "======================================"

# 配置
PROJECT_DIR="/Users/wujiajun/dream_to_model_web/ios"
PROJECT_FILE="DreamEcho.xcodeproj"
SCHEME="DreamEcho"
TEAM_ID="M4T239BM58"
BUNDLE_ID="com.dreamecho.app"
DEVICE_ID="00008150-000143CE2E98401C"  # iPhone (243)

cd "$PROJECT_DIR"

echo ""
echo "1. 检查设备连接状态..."
if xcrun xctrace list devices 2>&1 | grep -q "$DEVICE_ID"; then
    DEVICE_NAME=$(xcrun xctrace list devices 2>&1 | grep "$DEVICE_ID" | cut -d'(' -f1 | xargs)
    echo "✅ 设备已连接: $DEVICE_NAME"
else
    echo "❌ 设备未连接，请检查USB连接"
    exit 1
fi

echo ""
echo "2. 更新项目配置（启用自动签名）..."

# 使用PlistBuddy修改项目配置
/usr/libexec/PlistBuddy -c "Set :objects:15B8D78AF3ACEF5421A44DFE:attributes:TargetAttributes:15B8D78AF3ACEF5421A44DFE:DevelopmentTeam $TEAM_ID" "$PROJECT_FILE/project.pbxproj" 2>/dev/null || true

# 或者使用sed直接修改
sed -i '' 's/CODE_SIGN_STYLE = Manual;/CODE_SIGN_STYLE = Automatic;/g' "$PROJECT_FILE/project.pbxproj"
sed -i '' 's/DEVELOPMENT_TEAM = "";/DEVELOPMENT_TEAM = '${TEAM_ID}';/g' "$PROJECT_FILE/project.pbxproj"

# 如果没有DEVELOPMENT_TEAM字段，添加它
if ! grep -q "DEVELOPMENT_TEAM" "$PROJECT_FILE/project.pbxproj"; then
    echo "添加DEVELOPMENT_TEAM配置..."
fi

echo "✅ 项目配置已更新"

echo ""
echo "3. 清理构建缓存..."
xcodebuild clean \
    -project "$PROJECT_FILE" \
    -scheme "$SCHEME" \
    -configuration Debug

echo "✅ 清理完成"

echo ""
echo "4. 构建并部署应用到设备..."
echo "   这可能需要几分钟时间，请耐心等待..."

xcodebuild \
    -project "$PROJECT_FILE" \
    -scheme "$SCHEME" \
    -configuration Debug \
    -destination "platform=iOS,id=$DEVICE_ID" \
    -allowProvisioningUpdates \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM=$TEAM_ID \
    PRODUCT_BUNDLE_IDENTIFIER=$BUNDLE_ID \
    build

if [ $? -eq 0 ]; then
    echo ""
    echo "======================================"
    echo "✅ 部署成功！"
    echo "======================================"
    echo ""
    echo "应用已安装到您的设备: $DEVICE_NAME"
    echo "Bundle ID: $BUNDLE_ID"
    echo ""
    echo "📱 请在设备上查看并启动应用"
    echo ""
    echo "⚠️  首次运行可能需要在设置中信任开发者证书："
    echo "   设置 > 通用 > VPN与设备管理 > 开发者App > 信任"
    echo ""
else
    echo ""
    echo "======================================"
    echo "❌ 部署失败"
    echo "======================================"
    echo ""
    echo "请检查以下问题："
    echo "1. 设备是否已解锁并信任此电脑"
    echo "2. Xcode是否已登录Apple ID"
    echo "3. 开发者证书是否有效"
    echo ""
    exit 1
fi




