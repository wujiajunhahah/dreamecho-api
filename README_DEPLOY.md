# ✅ DreamEcho Render 部署 - 最终检查清单

## 🎯 已完成的准备工作

✅ **API密钥已找到**：
- DeepSeek: `sk-586e842eecfc45ba92eeceebed9b76dd`
- Tripo: `tsk_Ep2Vvovn4vAMITNVEjFjOacWy3jfuQtwIzJWV5lsS2T`
- 位置：`config.py`

✅ **代码已配置**：
- ✅ `render.yaml` 已创建
- ✅ `requirements.txt` 已更新（包含gunicorn）
- ✅ `app.py` 已修改支持云平台
- ✅ API密钥读取逻辑已优化（优先环境变量，fallback到config.py）

---

## 🚀 现在只需要3步！

### 第1步：推送代码到 GitHub

```bash
cd /Users/wujiajun/.cursor/worktrees/dream_to_model_web______/rZt9b

# 检查状态
git status

# 添加文件
git add .

# 提交
git commit -m "Prepare for Render deployment"

# 推送到GitHub
git push origin main
```

**注意**：`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` 是你的GitHub Token，不是仓库地址。

如果你还没有GitHub仓库，告诉我你的GitHub用户名，我可以帮你创建。

---

### 第2步：在 Render 部署（5分钟）

1. **访问**：https://dashboard.render.com

2. **创建 Web Service**：
   - 点击 "New +" → "Web Service"
   - 连接GitHub账号
   - 选择你的仓库

3. **配置**：
   - **Name**: `dreamecho-api`
   - **Build Command**: `pip install -r requirements.txt`（自动检测）
   - **Start Command**: `gunicorn app:app --bind 0.0.0.0:$PORT --timeout 300 --workers 2`
   - **Plan**: `Free`

4. **环境变量**（重要！）：
   在 "Environment" 标签添加：
   ```
   DEEPSEEK_API_KEY = sk-586e842eecfc45ba92eeceebed9b76dd
   TRIPO_API_KEY = tsk_Ep2Vvovn4vAMITNVEjFjOacWy3jfuQtwIzJWV5lsS2T
   FLASK_ENV = production
   ```

5. **创建并等待部署**（3-5分钟）

---

### 第3步：测试和配置 iOS

**测试API**：
访问 `https://你的URL.onrender.com/api/health`

应该返回：
```json
{"deepseek": "ok", "tripo": "ok"}
```

**更新 iOS 应用**：
```swift
// ios/DreamEchoApp/Sources/Configuration/AppConfiguration.swift
let base = environment["API_BASE_URL"] ?? info["API_BASE_URL"] as? String ?? "https://你的URL.onrender.com"
```

---

## ⚠️ 重要提示

### 1. 防止休眠（可选但推荐）
Render免费版15分钟无活动会休眠。

**解决方案**：使用 UptimeRobot（免费）
- 注册：https://uptimerobot.com
- 创建监控：每5分钟访问你的API
- 完全免费，应用不会休眠

### 2. 文件存储
- Render免费版文件存储是临时的
- 暂时够用，后续可以迁移到 Cloudflare R2（免费10GB）

---

## 📋 最终检查清单

- [ ] 代码已推送到 GitHub
- [ ] 在 Render 创建了 Web Service
- [ ] 设置了环境变量（`DEEPSEEK_API_KEY`, `TRIPO_API_KEY`）
- [ ] 部署成功，获取了URL
- [ ] 测试了 `/api/health` 端点
- [ ] 更新了 iOS 应用的 API URL
- [ ] （可选）设置了 UptimeRobot 防止休眠

---

## 🎯 你还需要什么？

1. **GitHub仓库地址**：如果你还没有，告诉我你的GitHub用户名
2. **遇到问题**：告诉我具体的错误信息
3. **测试帮助**：部署后我可以帮你测试API

**准备好了吗？开始部署吧！** 🚀

如果遇到任何问题，随时告诉我！

