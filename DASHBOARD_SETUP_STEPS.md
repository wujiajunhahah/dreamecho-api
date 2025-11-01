# 📋 Render Dashboard 设置步骤

## 🎯 必须设置的配置

### 1. Build Command
```
pip install --upgrade pip && pip install -r requirements.txt
```

### 2. Start Command（最重要！）
```
gunicorn app:app --bind 0.0.0.0:$PORT --timeout 300 --worker-class gevent --workers 1 --log-level info --worker-tmp-dir=/dev/shm
```

### 3. Health Check Path
```
/api/health
```

### 4. Python 版本
- 已在 `runtime.txt` 中指定：`python-3.11.9`
- Render 会自动读取

---

## ✅ 设置完成后

1. **保存所有更改**
2. **点击 "Manual Deploy" → "Deploy latest commit"**
3. **等待部署完成**

---

## 🔍 验证部署成功

部署成功后，日志中应该看到：
- ✅ `使用工人：gevent`（不是 sync）
- ✅ `数据库表初始化完成`
- ✅ 没有数据库错误

访问测试：
- ✅ `https://dreamecho-api.onrender.com/api/health` 返回正常
- ✅ `https://dreamecho-api.onrender.com/` 首页正常

---

## 📝 注意事项

- **Start Command** 必须包含 `--worker-class gevent`，否则会使用同步 worker
- **Health Check Path** 设置为 `/api/health`，避免依赖首页
- **Python 版本** 通过 `runtime.txt` 指定（已添加）

设置完成后重新部署即可！

