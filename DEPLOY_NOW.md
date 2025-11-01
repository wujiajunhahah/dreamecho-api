# DreamEcho Render 部署快速指南

## ✅ 已找到你的API密钥

**DeepSeek API**: `sk-586e842eecfc45ba92eeceebed9b76dd`  
**Tripo API**: `tsk_Ep2Vvovn4vAMITNVEjFjOacWy3jfuQtwIzJWV5lsS2T`

位置：`config.py` 文件中

---

## 🚀 现在只需要3步就可以部署！

### 第一步：推送代码到 GitHub

```bash
cd /Users/wujiajun/.cursor/worktrees/dream_to_model_web______/rZt9b

# 检查git状态
git status

# 添加所有文件
git add .

# 提交
git commit -m "Prepare for Render deployment"

# 推送到GitHub
git push origin main
```

**注意**：你提到的 `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` 是GitHub Token，不是仓库地址。

**如果你还没有GitHub仓库**：
1. 访问 https://github.com/new
2. 创建新仓库（如 `dreamecho-api`）
3. 然后运行：
   ```bash
   git remote add origin https://github.com/你的用户名/仓库名.git
   git push -u origin main
   ```

---

### 第二步：在 Render 部署（5分钟）

1. **访问 Render Dashboard**：https://dashboard.render.com

2. **创建 Web Service**：
   - 点击 "New +" → "Web Service"
   - 选择 "Connect GitHub"（连接你的GitHub账号）
   - 选择你的仓库

3. **配置服务**：
   - **Name**: `dreamecho-api`
   - **Build Command**: `pip install -r requirements.txt`（自动检测）
   - **Start Command**: `gunicorn app:app --bind 0.0.0.0:$PORT --timeout 300 --workers 2`
   - **Plan**: `Free`

4. **设置环境变量**（重要！）：
   点击 "Environment" 标签，添加：
   ```
   DEEPSEEK_API_KEY = sk-586e842eecfc45ba92eeceebed9b76dd
   TRIPO_API_KEY = tsk_Ep2Vvovn4vAMITNVEjFjOacWy3jfuQtwIzJWV5lsS2T
   FLASK_ENV = production
   ```
   （`SECRET_KEY` 和 `PORT` Render会自动处理）

5. **点击 "Create Web Service"**

6. **等待部署**（3-5分钟）

---

### 第三步：测试和配置

部署完成后，Render会给你一个URL，如：
`https://dreamecho-api.onrender.com`

**测试API**：
访问：`https://你的URL.onrender.com/api/health`

应该返回：
```json
{
  "deepseek": "ok",
  "tripo": "ok"
}
```

**更新 iOS 应用**：
修改 `ios/DreamEchoApp/Sources/Configuration/AppConfiguration.swift`：
```swift
let base = environment["API_BASE_URL"] ?? info["API_BASE_URL"] as? String ?? "https://你的URL.onrender.com"
```

---

## ⚠️ 重要提示

### 1. Render免费版会休眠
- **问题**：15分钟无活动后会休眠
- **解决**：使用 UptimeRobot（免费）
  - 注册：https://uptimerobot.com
  - 创建监控：每5分钟访问你的API
  - 这样应用就不会休眠了

### 2. 文件存储
- Render免费版文件存储是临时的
- 暂时够用，后续可以迁移到 Cloudflare R2（免费10GB）

---

## 📋 检查清单

- [ ] 代码已推送到 GitHub
- [ ] 在 Render 创建了 Web Service
- [ ] 设置了环境变量（`DEEPSEEK_API_KEY`, `TRIPO_API_KEY`）
- [ ] 部署成功，获取了URL
- [ ] 测试了 `/api/health` 端点
- [ ] 更新了 iOS 应用的 API URL
- [ ] （可选）设置了 UptimeRobot 防止休眠

---

## 🎯 你还需要什么？

1. **GitHub仓库地址**：如果你还没有仓库，告诉我你的GitHub用户名，我可以帮你创建
2. **遇到问题**：告诉我具体的错误信息，我会帮你解决

**准备好了吗？开始部署吧！** 🚀

