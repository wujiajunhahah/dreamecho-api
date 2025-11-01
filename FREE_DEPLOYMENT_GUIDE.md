# DreamEcho 免费部署方案指南

## ❌ Xcode Cloud 不适合后端部署

**Xcode Cloud** 是 Apple 的 CI/CD 服务，主要用于：
- ✅ 构建和测试 iOS 应用
- ✅ 自动化测试和分发
- ❌ **不能部署后端 API 服务**

你的后端是 **Python Flask**，需要独立的服务器或云平台。

---

## ✅ 免费后端部署方案（推荐顺序）

### 方案1：Render.com（最推荐，稳定免费）

#### 免费额度
- **Web服务**：免费，但15分钟无活动后会休眠
- **数据库**：PostgreSQL 免费（90天试用，之后需要付费）
- **静态文件存储**：有限制，建议用外部存储

#### 部署步骤

1. **准备代码**
```bash
# 创建 render.yaml 配置文件
cat > render.yaml <<EOF
services:
  - type: web
    name: dreamecho-api
    env: python
    buildCommand: pip install -r requirements.txt
    startCommand: gunicorn app:app
    envVars:
      - key: DEEPSEEK_API_KEY
        sync: false
      - key: TRIPO_API_KEY
        sync: false
      - key: SECRET_KEY
        generateValue: true
      - key: DATABASE_URL
        fromDatabase:
          name: dreamecho-db
          property: connectionString
databases:
  - name: dreamecho-db
    plan: free
EOF
```

2. **修改 app.py 支持 PostgreSQL**
```python
# 如果使用 PostgreSQL，修改数据库配置
import os
DATABASE_URL = os.environ.get('DATABASE_URL')
if DATABASE_URL and DATABASE_URL.startswith('postgres://'):
    DATABASE_URL = DATABASE_URL.replace('postgres://', 'postgresql://', 1)
app.config['SQLALCHEMY_DATABASE_URI'] = DATABASE_URL or 'sqlite:///dreams.db'
```

3. **在 Render 部署**
   - 注册：https://render.com（用 GitHub 登录）
   - 连接 GitHub 仓库
   - 选择 "New Web Service"
   - 选择你的仓库
   - Render 会自动检测 `render.yaml` 或手动配置
   - 设置环境变量：`DEEPSEEK_API_KEY`, `TRIPO_API_KEY`

4. **文件存储解决方案**
   - Render 免费版文件存储有限
   - **方案A**：使用 Cloudflare R2（免费10GB）
   - **方案B**：使用 GitHub Releases（免费但有限制）
   - **方案C**：使用临时存储（不推荐）

#### 优缺点
- ✅ 完全免费
- ✅ 自动 HTTPS
- ✅ 自动部署（连接 GitHub）
- ❌ 15分钟无活动会休眠（首次访问需要等待）
- ❌ 文件存储有限

---

### 方案2：Railway（免费额度充足）

#### 免费额度
- **$5/月免费额度**（约 ¥35）
- 超出后按使用量付费

#### 部署步骤

1. **创建 railway.json**
```json
{
  "build": {
    "builder": "NIXPACKS"
  },
  "deploy": {
    "startCommand": "gunicorn app:app",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

2. **在 Railway 部署**
   - 注册：https://railway.app（用 GitHub 登录）
   - 点击 "New Project" → "Deploy from GitHub"
   - 选择你的仓库
   - 添加环境变量
   - Railway 会自动检测并部署

3. **数据库**
   - Railway 提供免费 PostgreSQL
   - 自动配置 `DATABASE_URL`

#### 优缺点
- ✅ 有免费额度
- ✅ 不休眠
- ✅ 自动 HTTPS
- ✅ 简单易用
- ❌ 超出免费额度需要付费

---

### 方案3：Fly.io（全球边缘部署）

#### 免费额度
- **3个共享CPU VM**
- **3GB存储**
- **160GB出站流量/月**

#### 部署步骤

1. **安装 Fly CLI**
```bash
curl -L https://fly.io/install.sh | sh
```

2. **创建 fly.toml**
```bash
fly launch
# 选择 Python
# 选择地区（选择离你最近的）
```

3. **配置 fly.toml**
```toml
app = "dreamecho-api"
primary_region = "sin"  # 新加坡，离中国近

[build]
  builder = "paketobuildpacks/builder:base"

[env]
  PORT = "8080"

[[services]]
  internal_port = 8080
  protocol = "tcp"

  [[services.ports]]
    handlers = ["http"]
    port = 80

  [[services.ports]]
    handlers = ["tls", "http"]
    port = 443
```

4. **部署**
```bash
fly secrets set DEEPSEEK_API_KEY=your_key
fly secrets set TRIPO_API_KEY=your_key
fly deploy
```

#### 优缺点
- ✅ 免费额度充足
- ✅ 全球边缘部署（速度快）
- ✅ 不休眠
- ✅ 自动 HTTPS
- ❌ 配置稍复杂
- ❌ 需要命令行操作

---

### 方案4：PythonAnywhere（简单但有限制）

#### 免费额度
- **512MB存储**
- **1个Web应用**
- **只能在子域名访问**（如 `yourname.pythonanywhere.com`）

#### 部署步骤

1. **注册**：https://www.pythonanywhere.com
2. **上传代码**
   - 使用 Files → Upload 上传代码
   - 或在 Console 中使用 Git
3. **安装依赖**
```bash
pip3.10 install --user -r requirements.txt
```
4. **配置Web应用**
   - Web → Add a new web app
   - 选择 Manual configuration
   - Python 3.10
   - 设置 WSGI 文件路径

#### 优缺点
- ✅ 完全免费
- ✅ 简单易用
- ✅ 有Web界面
- ❌ 只能用子域名
- ❌ 存储限制（512MB）
- ❌ 性能有限

---

### 方案5：Replit（开发测试用）

#### 免费额度
- **512MB RAM**
- **1GB存储**
- **Always On需要付费**

#### 优缺点
- ✅ 完全免费（基础版）
- ✅ 在线IDE
- ✅ 简单部署
- ❌ 性能有限
- ❌ 不适合生产环境

---

### 方案6：本地开发 + ngrok（完全免费，仅测试）

#### 适合场景
- ✅ 开发测试
- ✅ 演示给朋友看
- ❌ 不适合生产环境

#### 步骤

1. **本地运行**
```bash
python app.py
```

2. **使用 ngrok**
```bash
# 安装 ngrok
brew install ngrok  # macOS
# 或下载：https://ngrok.com/download

# 创建免费账号获取 token
ngrok config add-authtoken YOUR_TOKEN

# 启动隧道
ngrok http 5001
```

3. **获取公网URL**
   - ngrok 会给你一个临时URL（如 `https://xxxx.ngrok.io`）
   - 更新 iOS 应用的 API URL

#### 优缺点
- ✅ 完全免费
- ✅ 适合开发测试
- ❌ URL 每次重启都会变（免费版）
- ❌ 不适合生产环境

---

## 🎯 推荐方案对比

| 方案 | 免费额度 | 休眠 | 文件存储 | 难度 | 推荐度 |
|------|---------|------|---------|------|--------|
| **Render** | ✅ 完全免费 | ⚠️ 15分钟休眠 | ❌ 有限 | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Railway** | ✅ $5/月 | ✅ 不休眠 | ✅ 有 | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Fly.io** | ✅ 充足 | ✅ 不休眠 | ✅ 有 | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| **PythonAnywhere** | ✅ 完全免费 | ✅ 不休眠 | ❌ 512MB | ⭐⭐ | ⭐⭐⭐ |
| **Replit** | ✅ 完全免费 | ⚠️ 需要付费 | ✅ 1GB | ⭐ | ⭐⭐ |
| **ngrok** | ✅ 完全免费 | ✅ 不休眠 | ✅ 本地 | ⭐ | ⭐⭐（仅测试） |

---

## 🚀 快速开始（推荐 Render）

### 第一步：准备代码

创建 `render.yaml`：

```yaml
services:
  - type: web
    name: dreamecho-api
    env: python
    buildCommand: pip install -r requirements.txt
    startCommand: gunicorn app:app --bind 0.0.0.0:$PORT
    envVars:
      - key: DEEPSEEK_API_KEY
        sync: false
      - key: TRIPO_API_KEY
        sync: false
      - key: SECRET_KEY
        generateValue: true
      - key: PORT
        value: 5001
```

### 第二步：修改 app.py 支持 Render

在 `app.py` 开头添加：

```python
import os

# Render 环境变量
if os.environ.get('RENDER'):
    # Render 使用 PostgreSQL
    DATABASE_URL = os.environ.get('DATABASE_URL')
    if DATABASE_URL and DATABASE_URL.startswith('postgres://'):
        DATABASE_URL = DATABASE_URL.replace('postgres://', 'postgresql://', 1)
        app.config['SQLALCHEMY_DATABASE_URI'] = DATABASE_URL
    else:
        app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///dreams.db'
else:
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///dreams.db'
```

### 第三步：添加 requirements.txt

确保包含 `gunicorn`：

```txt
flask
flask-sqlalchemy
flask-migrate
flask-login
gunicorn
# ... 其他依赖
```

### 第四步：在 Render 部署

1. 访问 https://render.com
2. 用 GitHub 登录
3. 点击 "New +" → "Web Service"
4. 连接你的 GitHub 仓库
5. Render 会自动检测配置
6. 添加环境变量：
   - `DEEPSEEK_API_KEY`
   - `TRIPO_API_KEY`
7. 点击 "Create Web Service"

### 第五步：获取URL并更新iOS应用

Render 会给你的应用一个URL，如：
- `https://dreamecho-api.onrender.com`

更新 iOS 应用的 `AppConfiguration.swift`：

```swift
let base = environment["API_BASE_URL"] ?? info["API_BASE_URL"] as? String ?? "https://dreamecho-api.onrender.com"
```

---

## ⚠️ 免费方案的限制

### 文件存储问题

所有免费方案都有文件存储限制。解决方案：

1. **使用 Cloudflare R2（推荐）**
   - 免费10GB存储
   - 免费出站流量
   - 需要修改代码上传到R2

2. **使用 GitHub Releases**
   - 每个文件最大2GB
   - 适合小文件

3. **使用临时存储**
   - 文件会定期清理
   - 不适合生产环境

### 休眠问题（Render）

Render 免费版15分钟无活动会休眠：
- **解决方案1**：使用 UptimeRobot（免费）定期ping你的API
- **解决方案2**：升级到付费版（$7/月）
- **解决方案3**：使用 Railway（不休眠）

---

## 🎯 最终推荐

### 如果你想要完全免费：
**Render.com** + **UptimeRobot**（防止休眠）+ **Cloudflare R2**（文件存储）

### 如果你想要稳定且少量付费：
**Railway**（$5/月免费额度，通常够用）

### 如果你想要最佳性能：
**Fly.io**（免费额度充足，全球边缘部署）

---

## 📝 下一步

1. 选择一个方案（推荐 Render）
2. 按照步骤部署
3. 测试 API 是否正常
4. 更新 iOS 应用的 API URL
5. 测试完整流程

需要我帮你创建具体的部署配置文件吗？

