# 🔧 Render 配置修正指南

## ❌ 发现的问题

### 1. Start Command 错误
**当前值**：`gunicorn your_application.wsgi` ❌  
**正确值**：`gunicorn app:app --bind 0.0.0.0:$PORT --timeout 300 --workers 2` ✅

**原因**：`your_application.wsgi` 是 Django 的示例命令，你的应用是 Flask，入口是 `app.py` 中的 `app` 对象。

### 2. DEEPSEEK_API_KEY 有错误
**检查**：确保值是正确的，没有多余空格或字符

---

## ✅ 修正步骤

### 第一步：修正 Start Command

在 Render 的配置页面中：

1. 找到 **"Start Command"** 字段
2. 删除当前的：`gunicorn your_application.wsgi`
3. 输入：
   ```
   gunicorn app:app --bind 0.0.0.0:$PORT --timeout 300 --workers 2
   ```

### 第二步：检查 DEEPSEEK_API_KEY

1. 找到 `DEEPSEEK_API_KEY` 字段
2. 确保值完全正确（没有多余空格）：
   ```
   sk-586e842eecfc45ba92eeceebed9b76dd
   ```
3. 如果有问题，删除后重新添加

### 第三步：其他环境变量

确保以下环境变量都已正确设置：

- **DEEPSEEK_API_KEY**: `sk-586e842eecfc45ba92eeceebed9b76dd`
- **TRIPO_API_KEY**: `tsk_Ep2Vvovn4vAMITNVEjFjOacWy3jfuQtwIzJWV5lsS2T`
- **FLASK_ENV**: `production`

### 第四步：保存并部署

1. 修正所有错误后，红色错误提示应该消失
2. 点击 **"Deploy Web Service"** 按钮
3. 等待3-5分钟构建和部署完成

---

## 📋 正确的配置检查清单

- [ ] Start Command 已改为：`gunicorn app:app --bind 0.0.0.0:$PORT --timeout 300 --workers 2`
- [ ] DEEPSEEK_API_KEY 值正确（无红色错误提示）
- [ ] TRIPO_API_KEY 已设置
- [ ] FLASK_ENV = production
- [ ] 没有红色错误提示
- [ ] 可以点击 "Deploy Web Service"

---

## 🎯 修正后

修正这两个问题后，应该就可以成功部署了！

如果还有问题，告诉我具体的错误信息。

