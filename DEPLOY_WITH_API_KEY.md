# Render API Key 配置

## ✅ API Key 已设置

你的 Render API Key: `5L4R-SXKF-G8K0-E0D4`

## 🚀 使用 API Key 部署

### 方法 1：一次性部署命令

```bash
export PATH="$HOME/.local/bin:$PATH"
export RENDER_API_KEY=5L4R-SXKF-G8K0-E0D4

# 获取服务 ID
SERVICE_ID=$(render services --output json --confirm | grep -B 5 "dreamecho-api" | grep '"id"' | head -1 | cut -d'"' -f4)

# 部署最新 commit
render deploys create $SERVICE_ID --commit 4697c25 --wait --confirm --output json
```

### 方法 2：直接指定服务 ID（如果已知）

```bash
export PATH="$HOME/.local/bin:$PATH"
export RENDER_API_KEY=5L4R-SXKF-G8K0-E0D4

# 部署最新 commit（替换 SERVICE_ID 为实际值）
render deploys create srv-xxxxx --commit 4697c25 --wait --confirm
```

### 方法 3：部署最新 commit

```bash
export PATH="$HOME/.local/bin:$PATH"
export RENDER_API_KEY=5L4R-SXKF-G8K0-E0D4

# 获取服务 ID
SERVICE_ID=$(render services --output json --confirm | grep -B 5 "dreamecho-api" | grep '"id"' | head -1 | cut -d'"' -f4)

# 部署最新 commit
render deploys create $SERVICE_ID --commit HEAD --wait --confirm
```

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

## 🔐 安全提示

⚠️ **不要将 API Key 提交到 Git 仓库！**

如果需要长期使用，可以：
1. 添加到环境变量（`.bashrc` 或 `.zshrc`）
2. 使用密钥管理工具
3. 只在 CI/CD 中临时设置

---

## ✅ 当前部署信息

- **最新 commit**: `4697c25` - `Fix: Upgrade SQLAlchemy for Python 3.13 compatibility...`
- **Python**: 3.11.9
- **SQLAlchemy**: >=2.0.36
- **Pillow**: 11.0.0

现在就运行上面的命令来部署吧！

