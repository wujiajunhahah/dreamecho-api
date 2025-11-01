# DreamEcho 快速部署指南（免费方案）

## 🎯 最简单的免费部署方案：Render.com

### ⚡ 5分钟快速部署

#### 第一步：准备代码（已完成）
✅ 已创建 `render.yaml` 配置文件
✅ 已更新 `requirements.txt` 包含 `gunicorn`
✅ 已修改 `app.py` 支持云平台

#### 第二步：推送代码到 GitHub

```bash
git add .
git commit -m "Prepare for Render deployment"
git push origin main
```

#### 第三步：在 Render 部署

1. **访问 Render**：https://render.com
2. **注册账号**：使用 GitHub 账号登录（推荐）
3. **创建新服务**：
   - 点击 "New +" → "Web Service"
   - 选择你的 GitHub 仓库
   - Render 会自动检测 `render.yaml` 配置
4. **设置环境变量**：
   - `DEEPSEEK_API_KEY` = 你的 DeepSeek API 密钥
   - `TRIPO_API_KEY` = 你的 Tripo API 密钥
   - `SECRET_KEY` = Render 会自动生成（或手动设置）
5. **点击 "Create Web Service"**

#### 第四步：等待部署完成

- Render 会自动构建和部署
- 构建完成后，你会得到一个URL，如：
  - `https://dreamecho-api.onrender.com`

#### 第五步：更新 iOS 应用配置

更新 `ios/DreamEchoApp/Sources/Configuration/AppConfiguration.swift`：

```swift
// 将默认 URL 改为你的 Render URL
let base = environment["API_BASE_URL"] ?? info["API_BASE_URL"] as? String ?? "https://dreamecho-api.onrender.com"
```

---

## ⚠️ Render 免费版的限制

### 休眠问题
- **问题**：15分钟无活动后会休眠
- **解决方案**：
  1. **使用 UptimeRobot（推荐，免费）**：
     - 注册：https://uptimerobot.com
     - 创建监控：每5分钟ping你的API
     - 这样应用就不会休眠了
  2. **或者升级付费版**（$7/月，不休眠）

### 文件存储限制
- **问题**：Render 免费版文件存储有限
- **解决方案**：
  1. **使用 Cloudflare R2（推荐，免费10GB）**
  2. **暂时使用本地存储**（小规模用户够用）

---

## 🔄 其他免费方案快速对比

### Railway（推荐，有免费额度）
- **优点**：不休眠，自动部署，简单
- **缺点**：$5/月免费额度（通常够用）
- **部署**：连接 GitHub，自动检测，设置环境变量即可

### Fly.io（推荐，性能好）
- **优点**：不休眠，全球边缘部署，速度快
- **缺点**：配置稍复杂
- **部署**：需要安装 CLI，运行 `fly launch`

### PythonAnywhere（最简单）
- **优点**：完全免费，有Web界面
- **缺点**：只能用子域名（如 `yourname.pythonanywhere.com`）
- **部署**：上传代码，配置Web应用

---

## 📋 部署检查清单

- [ ] 代码已推送到 GitHub
- [ ] 在 Render 创建了 Web Service
- [ ] 设置了环境变量（`DEEPSEEK_API_KEY`, `TRIPO_API_KEY`）
- [ ] 部署成功，获取了URL
- [ ] 更新了 iOS 应用的 API URL
- [ ] 测试了 API 是否正常
- [ ] （可选）设置了 UptimeRobot 防止休眠

---

## 🚀 下一步

1. **立即部署**：按照上面的步骤在 Render 部署
2. **测试API**：访问 `https://你的URL.onrender.com/api/health` 测试
3. **更新iOS应用**：修改 API URL
4. **设置监控**：使用 UptimeRobot 防止休眠

---

## 💡 提示

- **完全免费**：Render + UptimeRobot + Cloudflare R2（如果需要）
- **成本**：$0/月 ✅
- **适合**：个人项目、小规模用户、测试环境

需要帮助部署吗？告诉我你选择哪个平台，我可以提供更详细的指导！

