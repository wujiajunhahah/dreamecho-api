# DreamEcho Render 部署检查清单

## ✅ 已完成的准备工作

1. ✅ **API密钥已找到**：
   - DeepSeek API: `sk-586e842eecfc45ba92eeceebed9b76dd`
   - Tripo API: `tsk_Ep2Vvovn4vAMITNVEjFjOacWy3jfuQtwIzJWV5lsS2T`
   - 位置：`config.py` 文件中

2. ✅ **代码已准备**：
   - `render.yaml` 配置文件已创建
   - `requirements.txt` 已更新（包含 gunicorn）
   - `app.py` 已修改支持云平台

---

## 📋 Render 部署步骤

### 第一步：推送代码到 GitHub

```bash
cd /Users/wujiajun/.cursor/worktrees/dream_to_model_web______/rZt9b

# 检查当前状态
git status

# 添加所有文件
git add .

# 提交
git commit -m "Prepare for Render deployment"

# 推送到GitHub（替换为你的GitHub仓库地址）
git remote -v  # 查看远程仓库
git push origin main  # 或 master，根据你的分支名
```

**注意**：你提到的 `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` 看起来像GitHub Personal Access Token，不是仓库地址。你需要：
- 如果你还没有GitHub仓库，先创建一个
- 或者告诉我你的GitHub仓库URL

---

### 第二步：在 Render 创建 Web Service

1. **访问 Render Dashboard**：https://dashboard.render.com

2. **创建新服务**：
   - 点击 "New +" → "Web Service"
   - 选择 "Connect GitHub"（如果还没连接，先连接你的GitHub账号）
   - 选择你的仓库

3. **配置服务**：
   - **Name**: `dreamecho-api`（或你喜欢的名字）
   - **Environment**: `Python 3`
   - **Build Command**: `pip install -r requirements.txt`（Render会自动检测）
   - **Start Command**: `gunicorn app:app --bind 0.0.0.0:$PORT --timeout 300 --workers 2`
   - **Plan**: `Free`（免费版）

4. **设置环境变量**（重要！）：
   点击 "Environment" 标签，添加以下变量：
   
   ```
   DEEPSEEK_API_KEY = sk-586e842eecfc45ba92eeceebed9b76dd
   TRIPO_API_KEY = tsk_Ep2Vvovn4vAMITNVEjFjOacWy3jfuQtwIzJWV5lsS2T
   SECRET_KEY = （留空，Render会自动生成，或手动设置一个随机字符串）
   PORT = 5001（可选，Render会自动设置）
   FLASK_ENV = production
   ```

5. **点击 "Create Web Service"**

---

### 第三步：等待部署完成

- Render 会自动：
  1. 克隆你的代码
  2. 安装依赖（`pip install -r requirements.txt`）
  3. 启动应用（`gunicorn app:app`）
  4. 分配URL（如 `https://dreamecho-api.onrender.com`）

- 部署时间：通常 3-5 分钟

---

### 第四步：测试部署

部署完成后，访问以下URL测试：

1. **健康检查**：
   ```
   https://你的URL.onrender.com/api/health
   ```
   应该返回：
   ```json
   {
     "deepseek": "ok",
     "tripo": "ok"
   }
   ```

2. **主页**：
   ```
   https://你的URL.onrender.com/
   ```

---

### 第五步：更新 iOS 应用配置

部署成功后，更新 iOS 应用的 API URL：

1. 打开 `ios/DreamEchoApp/Sources/Configuration/AppConfiguration.swift`

2. 修改默认 URL：
   ```swift
   let base = environment["API_BASE_URL"] ?? info["API_BASE_URL"] as? String ?? "https://你的URL.onrender.com"
   ```

3. 或者在 Xcode 中设置环境变量：
   - Scheme → Edit Scheme → Run → Arguments → Environment Variables
   - 添加：`API_BASE_URL = https://你的URL.onrender.com`

---

## ⚠️ 重要注意事项

### 1. 数据库初始化

首次部署需要初始化数据库：

**选项A：通过API自动初始化**（推荐）
- 当第一次访问应用时，Flask会自动创建数据库表
- 如果使用SQLite，文件会保存在Render的临时存储中

**选项B：使用PostgreSQL**（推荐生产环境）
- 在Render创建PostgreSQL数据库（免费）
- 更新 `render.yaml` 添加数据库配置
- 设置 `DATABASE_URL` 环境变量

### 2. 文件存储

Render免费版的文件存储是临时的，重启后会丢失。

**解决方案**：
- **开发测试**：暂时使用本地存储（小文件）
- **生产环境**：使用 Cloudflare R2（免费10GB）或 AWS S3

### 3. 防止休眠

Render免费版15分钟无活动会休眠。

**解决方案**：
- 使用 **UptimeRobot**（免费）：
  1. 注册：https://uptimerobot.com
  2. 创建监控：每5分钟访问你的API
  3. 这样应用就不会休眠了

---

## 🔧 如果遇到问题

### 问题1：构建失败
- 检查 `requirements.txt` 是否包含所有依赖
- 查看 Render 的构建日志

### 问题2：API密钥错误
- 确认环境变量已正确设置
- 检查环境变量名称是否正确（`DEEPSEEK_API_KEY`, `TRIPO_API_KEY`）

### 问题3：数据库错误
- 确认数据库已初始化
- 检查数据库连接字符串

### 问题4：应用启动失败
- 检查 `gunicorn` 是否在 `requirements.txt` 中
- 检查启动命令是否正确

---

## 📝 快速检查清单

- [ ] 代码已推送到 GitHub
- [ ] 在 Render 创建了 Web Service
- [ ] 设置了环境变量（`DEEPSEEK_API_KEY`, `TRIPO_API_KEY`）
- [ ] 部署成功，获取了URL
- [ ] 测试了 `/api/health` 端点
- [ ] 更新了 iOS 应用的 API URL
- [ ] （可选）设置了 UptimeRobot 防止休眠

---

## 🚀 下一步

1. **立即部署**：按照上面的步骤在 Render 部署
2. **测试API**：访问健康检查端点确认一切正常
3. **更新iOS应用**：修改 API URL
4. **设置监控**：使用 UptimeRobot 防止休眠

---

## 💡 提示

- GitHub Token (`ghp_...`) 用于认证，不是仓库地址
- 如果你还没有GitHub仓库，我可以帮你创建一个
- 或者告诉我你的GitHub用户名，我可以帮你检查仓库配置

准备好了吗？告诉我你的GitHub仓库地址，或者遇到任何问题都可以问我！

