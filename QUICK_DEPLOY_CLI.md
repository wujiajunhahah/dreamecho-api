# ✅ Render CLI 已安装

## 🚀 快速部署步骤

### 1. 登录 Render CLI

运行以下命令（会打开浏览器让你授权）：

```bash
export PATH="$HOME/.local/bin:$PATH"
render login
```

### 2. 获取服务 ID

```bash
export PATH="$HOME/.local/bin:$PATH"
render services --output json | grep -A 10 "dreamecho-api"
```

找到 `id` 字段，格式如 `srv-d42rhlripnbc73c41v20`。

### 3. 部署最新 commit

```bash
export PATH="$HOME/.local/bin:$PATH"
render deploys create srv-d42rhlripnbc73c41v20 --commit 4697c25 --wait --confirm
```

或者部署最新 commit：

```bash
export PATH="$HOME/.local/bin:$PATH"
render deploys create srv-d42rhlripnbc73c41v20 --commit HEAD --wait --confirm
```

### 4. 查看部署状态

```bash
export PATH="$HOME/.local/bin:$PATH"
render deploys list srv-d42rhlripnbc73c41v20
```

### 5. 查看实时日志

```bash
export PATH="$HOME/.local/bin:$PATH"
render logs srv-d42rhlripnbc73c41v20 --tail
```

---

## 📋 当前配置

- **最新 commit**: `4697c25` - `Fix: Upgrade SQLAlchemy for Python 3.13 compatibility...`
- **Python**: 3.11.9
- **SQLAlchemy**: >=2.0.36
- **Pillow**: 11.0.0
- **Gunicorn**: 1 worker, 80s timeout

---

## 🔗 参考文档

- Render CLI 文档：https://render.com/docs/cli
- 部署特定 commit：https://render.com/docs/cli#deploys-createservice_id

---

**现在运行 `render login` 开始部署！**

