# ⚠️ 紧急：Render 仍在读取旧代码

## 🔴 问题

Render 还在使用旧的 commit，导致：
- ❌ 读取 `Pillow==10.1.0`（应该是 `Pillow==11.0.0`）
- ❌ 使用 Python 3.13（应该是 Python 3.11.9）

## ✅ 解决方案

### 方法 1：在 Render Dashboard 手动选择最新 commit

1. **进入 Render Dashboard**
   - https://dashboard.render.com
   - 进入 `dreamecho-api` 服务

2. **手动部署最新 commit**
   - 点击 **"Manual Deploy"** 按钮
   - 选择 **"Deploy specific commit"** 或 **"Deploy a commit"**
   - 在列表中找到最新的 commit：
     - `b04fed9` - `Fix: Add database migration, fix static resource paths...`
     - 或 `9539b9d` - `Add runtime.txt to specify Python 3.11.9`
   - 点击该 commit 进行部署

### 方法 2：重新连接 GitHub 仓库

1. 在 Render Dashboard：
   - 点击 **"Settings"** 标签
   - 找到 **"Repository"** 部分
   - 点击 **"Disconnect"** 断开连接
   - 然后重新 **"Connect GitHub"**
   - 选择仓库：`wujiajunhahah/dreamecho-api`
   - 选择分支：`main`

2. 重新部署会自动使用最新 commit

### 方法 3：使用 Render CLI 强制部署

```bash
export PATH="$HOME/.local/bin:$PATH"
export RENDER_API_KEY=5L4R-SXKF-G8K0-E0D4

# 获取服务 ID
SERVICE_ID=$(render services --output json --confirm | grep -B 5 "dreamecho-api" | grep '"id"' | head -1 | cut -d'"' -f4)

# 部署最新 commit
render deploys create $SERVICE_ID --commit HEAD --wait --confirm
```

---

## 📋 最新代码状态

- ✅ `requirements.txt`: `Pillow==11.0.0`（不是 10.1.0）
- ✅ `runtime.txt`: `python-3.11.9`
- ✅ `render.yaml`: 已配置 gevent worker 和 flask db upgrade
- ✅ 数据库迁移文件已创建
- ✅ 静态资源路径已修复

---

## 🎯 验证 GitHub 仓库

访问：https://github.com/wujiajunhahah/dreamecho-api

确认：
- ✅ 最新 commit 是 `b04fed9` 或更新的
- ✅ `requirements.txt` 中 Pillow 是 `11.0.0`
- ✅ `runtime.txt` 内容是 `python-3.11.9`

---

## ⚠️ 重要提示

**必须在 Render Dashboard 手动选择最新的 commit 来部署！**

自动部署可能没有检测到最新代码，需要手动触发。

现在去 Render Dashboard，使用 "Manual Deploy" → "Deploy specific commit" 选择最新的 commit！

