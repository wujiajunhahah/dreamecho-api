#!/bin/bash

# 推送项目到mengjingapp仓库的脚本

echo "======================================"
echo "推送项目到 mengjingapp 仓库"
echo "======================================"

cd /Users/wujiajun/dream_to_model_web

echo ""
echo "1. 检查当前Git状态..."
git status --short

echo ""
echo "2. 检查远程仓库配置..."
git remote -v

echo ""
echo "3. 开始推送到 mengjingapp..."
echo "   目标仓库: https://github.com/wujiajunhahah/mengjingapp.git"
echo ""

# 尝试推送
git push mengjingapp main

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 成功！项目已推送到 mengjingapp 仓库"
    echo "🔗 查看仓库: https://github.com/wujiajunhahah/mengjingapp"
else
    echo ""
    echo "❌ 推送失败。可能需要身份验证。"
    echo ""
    echo "请尝试以下步骤："
    echo "1. 确保您已登录GitHub"
    echo "2. 如果需要，请创建个人访问令牌(Personal Access Token)"
    echo "3. 手动运行: git push mengjingapp main"
fi

echo ""
echo "======================================"






