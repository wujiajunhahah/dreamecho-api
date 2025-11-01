# 🚨 紧急：Render 仍在读取旧 commit！

## 🔴 问题

Render 还在使用旧的 commit `1277053`，导致：
- ❌ `Pillow==10.1.0`（应该是 `11.0.0`）
- ❌ `SQLAlchemy==2.0.23`（应该是 `>=2.0.36`）
- ❌ Python 3.13.4（应该是 3.11.9）
- ❌ Build Command 没有 `flask db upgrade`

## ✅ 解决方案：必须在 Render Dashboard 手动操作

### 步骤 1：手动部署最新 commit

1. **进入 Render Dashboard**
   - https://dashboard.render.com
   - 进入 `dreamecho-api` 服务

2. **手动选择最新 commit**
   - 点击 **"Manual Deploy"** 按钮
   - 选择 **"Deploy specific commit"** 或 **"Deploy a commit"**
   - 在列表中查找最新的 commit：
     - `9257d6a` - `Fix: Remove gevent dependency (Python 3.13 incompatible)...`
     - `4f422b6` - `Fix: Remove gevent worker...`
     - `b04fed9` - `Fix: Add database migration...`
   - **点击最新的 commit 进行部署**

### 步骤 2：更新 Build Command

在 "Build & Deploy" → "Build Command"：
```
pip install --upgrade pip && pip install -r requirements.txt && flask db upgrade
```

### 步骤 3：更新 Start Command

在 "Build & Deploy" → "Start Command"：
```
gunicorn app:app --bind 0.0.0.0:$PORT --timeout 300 --workers 1 --log-level info --worker-tmp-dir=/dev/shm
```

### 步骤 4：设置 Python 版本（如果可能）

在 "Settings" 中找到 "Python Version"：
- 选择 **Python 3.11**
- 或确保 `runtime.txt` 文件存在（已在代码中）

---

## 📋 验证 GitHub 仓库

访问：https://github.com/wujiajunhahah/dreamecho-api

确认最新 commit 是：
- `9257d6a` - `Fix: Remove gevent dependency...`
- `requirements.txt` 中：
  - `Pillow==11.0.0`（不是 10.1.0）
  - `SQLAlchemy>=2.0.36`（不是 2.0.23）
  - 没有 `gevent`

---

## 🎯 关键操作

**最重要的**：在 Render Dashboard 使用 "Manual Deploy" → "Deploy specific commit" 选择最新的 commit！

自动部署没有检测到最新代码，必须手动选择！

---

## ✅ 最新代码状态

- ✅ `Pillow==11.0.0`
- ✅ `SQLAlchemy>=2.0.36`
- ✅ gevent 已移除
- ✅ 数据库迁移已配置
- ✅ `runtime.txt`: `python-3.11.9`

现在去 Render Dashboard，手动选择最新的 commit 部署！

