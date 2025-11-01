# 🚀 使用 Render API Key 部署

## ✅ API Key 已配置

你的 Render API Key: `5L4R-SXKF-G8K0-E0D4`

## 快速部署

### 方法 1：使用部署脚本（推荐）

```bash
export PATH="$HOME/.local/bin:$PATH"
./deploy_render.sh
```

### 方法 2：手动部署命令

```bash
export PATH="$HOME/.local/bin:$PATH"
export RENDER_API_KEY=5L4R-SXKF-G8K0-E0D4

# 1. 设置 workspace
render workspace set --output json --confirm

# 2. 获取服务 ID
SERVICE_ID=$(render services --output json --confirm | grep -B 5 "dreamecho-api" | grep '"id"' | head -1 | cut -d'"' -f4)

# 3. 部署最新 commit
render deploys create $SERVICE_ID --commit 4697c25 --wait --confirm
```

### 方法 3：在 Render Dashboard 部署

1. 访问：https://dashboard.render.com
2. 进入 `dreamecho-api` 服务
3. 点击 "Manual Deploy" → "Deploy latest commit"

---

## 📋 查看部署状态

```bash
export PATH="$HOME/.local/bin:$PATH"
export RENDER_API_KEY=5L4R-SXKF-G8K0-E0D4

# 获取服务 ID
SERVICE_ID=$(render services --output json --confirm | grep -B 5 "dreamecho-api" | grep '"id"' | head -1 | cut -d'"' -f4)

# 查看部署列表
render deploys list $SERVICE_ID --output json --confirm
```

---

## 📊 查看实时日志

```bash
export PATH="$HOME/.local/bin:$PATH"
export RENDER_API_KEY=5L4R-SXKF-G8K0-E0D4

# 获取服务 ID
SERVICE_ID=$(render services --output json --confirm | grep -B 5 "dreamecho-api" | grep '"id"' | head -1 | cut -d'"' -f4)

# 查看实时日志
render logs $SERVICE_ID --tail
```

---

## ✅ 当前部署信息

- **最新 commit**: `4697c25` - `Fix: Upgrade SQLAlchemy for Python 3.13 compatibility...`
- **Python**: 3.11.9
- **SQLAlchemy**: >=2.0.36
- **Pillow**: 11.0.0

---

## 🔐 安全提示

⚠️ **API Key 已保存在脚本中，不要提交到 Git！**

运行 `./deploy_render.sh` 开始部署！

