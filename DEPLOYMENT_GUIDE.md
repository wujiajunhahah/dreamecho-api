# DreamEcho 部署指南

## ⚠️ 重要：Vercel不适合这个项目

### 为什么Vercel不适合？
1. **执行时间限制**：
   - Vercel Serverless Functions 免费版最多10秒，Pro版最多60秒
   - 你的3D模型生成需要几分钟（调用DeepSeek + Tripo API）

2. **文件存储限制**：
   - Vercel只支持临时文件（/tmp目录）
   - 你的3D模型（.glb文件）需要持久化存储在 `static/models/` 目录
   - 文件需要能被iOS应用访问（通过URL）

3. **长时间运行任务**：
   - 你使用 `threading.Thread` 进行异步处理
   - Vercel Serverless不支持后台线程

4. **SSE流式事件**：
   - `/api/dreams/<id>/events` 端点需要长连接
   - Vercel对长连接支持有限

---

## ✅ 推荐部署方案

### 方案A：阿里云ECS + 域名 + OSS（推荐，性价比高）

#### 1. 服务器配置
- **推荐配置**：2核4GB内存，40GB SSD，1Mbps带宽
- **价格**：约 ¥200-300/月
- **系统**：Ubuntu 22.04 LTS

#### 2. 域名配置
- 在阿里云购买域名（如 `dreamecho.ai`）
- 配置DNS解析：A记录指向服务器IP

#### 3. 文件存储（可选，推荐）
- **阿里云OSS**：用于存储3D模型文件
  - 价格：存储约 ¥0.12/GB/月，流量约 ¥0.5/GB
  - 优点：CDN加速、可扩展、高可用
  - 代码修改：需要添加OSS上传功能

#### 4. 部署步骤

```bash
# 1. 连接到服务器
ssh root@your-server-ip

# 2. 安装基础环境
apt update
apt install -y python3 python3-pip nginx git

# 3. 安装Python依赖
pip3 install -r requirements.txt

# 4. 配置环境变量
nano /etc/environment
# 添加：
# DEEPSEEK_API_KEY=your_key
# TRIPO_API_KEY=your_key
# FLASK_SECRET_KEY=your_secret_key

# 5. 使用Gunicorn运行Flask应用
pip3 install gunicorn
gunicorn -w 4 -b 127.0.0.1:5001 app:app --daemon

# 6. 配置Nginx反向代理
nano /etc/nginx/sites-available/dreamecho
```

Nginx配置示例：
```nginx
server {
    listen 80;
    server_name api.dreamecho.ai;

    client_max_body_size 100M;  # 支持大文件上传

    location / {
        proxy_pass http://127.0.0.1:5001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # SSE支持
        proxy_buffering off;
        proxy_cache off;
        proxy_read_timeout 300s;
    }

    # 静态文件（3D模型）
    location /static/ {
        alias /path/to/your/app/static/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
```

```bash
# 7. 启用Nginx配置
ln -s /etc/nginx/sites-available/dreamecho /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx

# 8. 配置SSL证书（免费Let's Encrypt）
apt install certbot python3-certbot-nginx
certbot --nginx -d api.dreamecho.ai
```

#### 5. 成本估算
- ECS服务器：¥200-300/月
- 域名：¥50-100/年
- OSS（可选）：¥20-50/月（取决于使用量）
- **总计：约¥250-350/月**

---

### 方案B：Railway / Render / Fly.io（更简单，但更贵）

#### Railway（推荐）
- **价格**：$5/月起（约¥35/月），按使用量计费
- **优点**：
  - 自动部署（连接GitHub）
  - 内置PostgreSQL数据库
  - 自动SSL证书
  - 支持长时间运行任务
- **缺点**：
  - 文件存储需要外部服务（AWS S3/Cloudflare R2）
  - 相对较贵

#### Render
- **价格**：$7/月起（约¥50/月）
- **优点**：类似Railway，但更稳定
- **缺点**：免费版会休眠，不适合生产环境

#### Fly.io
- **价格**：按使用量计费，约$5-10/月
- **优点**：全球边缘部署，速度快
- **缺点**：配置复杂，文件存储需要外部服务

---

### 方案C：腾讯云轻量应用服务器（性价比高）

- **价格**：¥60-120/月（2核4GB）
- **优点**：国内访问快，价格便宜
- **配置**：类似阿里云ECS

---

## 📋 部署前检查清单

### 1. 代码修改
- [ ] 确保所有环境变量都通过配置文件读取
- [ ] 移除硬编码的API密钥
- [ ] 确认数据库路径（SQLite需要持久化目录）

### 2. 文件存储
- [ ] 选择存储方案：
  - 方案A：本地存储（ECS服务器）
  - 方案B：OSS/S3对象存储（推荐，可扩展）

### 3. 环境变量
需要设置以下环境变量：
```bash
DEEPSEEK_API_KEY=your_deepseek_key
TRIPO_API_KEY=your_tripo_key
FLASK_SECRET_KEY=your_secret_key
FLASK_ENV=production
```

### 4. 数据库
- [ ] SQLite：适合小规模（<1000用户）
- [ ] PostgreSQL：推荐生产环境（Railway/Render内置）
- [ ] MySQL：阿里云RDS（可选）

### 5. iOS应用配置
更新 `ios/DreamEchoApp/Sources/Configuration/AppConfiguration.swift`：
```swift
// 生产环境
let base = environment["API_BASE_URL"] ?? info["API_BASE_URL"] as? String ?? "https://api.dreamecho.ai"
```

---

## 🚀 快速部署脚本（阿里云ECS）

创建 `deploy.sh`：

```bash
#!/bin/bash

# 更新系统
apt update && apt upgrade -y

# 安装Python和依赖
apt install -y python3 python3-pip nginx git certbot python3-certbot-nginx

# 克隆代码（或上传）
cd /opt
git clone your-repo-url dream-echo
cd dream-echo

# 安装Python依赖
pip3 install -r requirements.txt

# 创建systemd服务
cat > /etc/systemd/system/dreamecho.service <<EOF
[Unit]
Description=DreamEcho Flask App
After=network.target

[Service]
User=www-data
WorkingDirectory=/opt/dream-echo
Environment="PATH=/usr/bin"
ExecStart=/usr/local/bin/gunicorn -w 4 -b 127.0.0.1:5001 app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 启动服务
systemctl daemon-reload
systemctl enable dreamecho
systemctl start dreamecho

# 配置Nginx（见上方配置）
# 配置SSL证书
certbot --nginx -d api.dreamecho.ai

echo "部署完成！"
```

---

## 💡 推荐配置总结

### 小规模（<100用户）
- **服务器**：阿里云ECS 2核2GB（¥100/月）
- **存储**：本地存储（服务器磁盘）
- **域名**：阿里云域名（¥50/年）
- **总计**：约¥150/月

### 中等规模（100-1000用户）
- **服务器**：阿里云ECS 2核4GB（¥200/月）
- **存储**：阿里云OSS（¥50/月）
- **数据库**：SQLite或PostgreSQL
- **域名**：阿里云域名（¥50/年）
- **总计**：约¥250/月

### 大规模（>1000用户）
- **服务器**：阿里云ECS 4核8GB（¥500/月）
- **存储**：阿里云OSS + CDN（¥200/月）
- **数据库**：阿里云RDS PostgreSQL（¥300/月）
- **负载均衡**：阿里云SLB（¥100/月）
- **总计**：约¥1100/月

---

## 🔧 如果一定要用Vercel（不推荐）

如果坚持使用Vercel，需要进行重大重构：

1. **使用Vercel Edge Functions + 外部API**
   - 将3D生成任务移到外部服务（如单独的后端服务器）
   - Vercel只负责API网关

2. **文件存储迁移到外部**
   - 使用Vercel Blob Storage（付费）
   - 或使用Cloudflare R2 / AWS S3

3. **使用队列系统**
   - Vercel Functions → 任务队列（如RabbitMQ）→ 工作服务器
   - 复杂度大大增加

**结论**：不推荐Vercel，使用ECS或Railway更合适。

