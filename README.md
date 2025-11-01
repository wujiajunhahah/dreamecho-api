# DreamEcho API Backend

DreamEcho 梦境转3D模型平台的后端API服务。

## 🚀 快速部署到 Render

### 1. 连接 GitHub 仓库到 Render

1. 访问 https://dashboard.render.com
2. 点击 "New +" → "Web Service"
3. 选择 "Connect GitHub"（如果还没连接）
4. 选择仓库：`wujiajunhahah/dreamecho-api`

### 2. 配置服务

Render会自动检测 `render.yaml` 配置，但需要手动设置环境变量：

**环境变量**：
- `DEEPSEEK_API_KEY` = `sk-586e842eecfc45ba92eeceebed9b76dd`
- `TRIPO_API_KEY` = `tsk_Ep2Vvovn4vAMITNVEjFjOacWy3jfuQtwIzJWV5lsS2T`
- `FLASK_ENV` = `production`

### 3. 部署

点击 "Create Web Service"，等待3-5分钟部署完成。

### 4. 测试

部署完成后访问：`https://你的URL.onrender.com/api/health`

应该返回：
```json
{
  "deepseek": "ok",
  "tripo": "ok"
}
```

## 📝 API 端点

- `GET /api/health` - 健康检查
- `POST /api/auth/login` - 登录
- `POST /api/auth/register` - 注册
- `GET /api/session` - 获取会话
- `GET /api/dreams` - 获取梦境列表
- `POST /api/dreams` - 创建新梦境
- `GET /api/dreams/<id>` - 获取单个梦境
- `GET /api/dreams/<id>/events` - 流式事件（SSE）

## ⚠️ 注意事项

- Render免费版15分钟无活动会休眠
- 建议使用 UptimeRobot 每5分钟ping一次API防止休眠
- 文件存储是临时的，重启后会丢失

## 📚 更多信息

查看 `README_DEPLOY.md` 获取详细部署指南。
