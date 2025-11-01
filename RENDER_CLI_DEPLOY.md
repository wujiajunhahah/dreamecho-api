# 🚀 使用 Render CLI 部署

## 安装 Render CLI

如果还没安装，运行：

```bash
# macOS (Homebrew)
brew install render

# 或 Linux/macOS (直接安装)
curl -fsSL https://raw.githubusercontent.com/render-oss/cli/refs/heads/main/bin/install.sh | sh
```

## 登录

```bash
render login
```

这会打开浏览器让你授权。

## 获取服务 ID

```bash
render services --output json
```

找到 `dreamecho-api` 服务的 `id`（格式如 `srv-xxxxx`）。

## 部署最新 commit

```bash
# 部署最新 commit
render deploys create <SERVICE_ID> --commit HEAD --wait

# 或指定特定 commit
render deploys create <SERVICE_ID> --commit 4697c25 --wait
```

## 查看部署日志

```bash
render deploys list <SERVICE_ID>
```

## 查看实时日志

```bash
render logs <SERVICE_ID> --tail
```

---

## 当前状态

- **最新 commit**: `4697c25` - `Fix: Upgrade SQLAlchemy for Python 3.13 compatibility...`
- **GitHub 仓库**: https://github.com/wujiajunhahah/dreamecho-api
- **修复内容**:
  - ✅ SQLAlchemy >= 2.0.36
  - ✅ Python 3.11.9
  - ✅ Pillow 11.0.0
  - ✅ Gunicorn 优化配置

---

## 快速部署命令

```bash
# 1. 登录（如果还没登录）
render login

# 2. 获取服务 ID
SERVICE_ID=$(render services --output json | grep -A 5 "dreamecho-api" | grep "id" | head -1 | cut -d'"' -f4)

# 3. 部署最新 commit
render deploys create $SERVICE_ID --commit HEAD --wait --confirm
```

---

参考文档：https://render.com/docs/cli

