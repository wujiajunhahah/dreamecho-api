# 📋 Render Dashboard 最终配置

## 🎯 必须设置的配置

### 1. Build Command
```
pip install --upgrade pip && pip install -r requirements.txt && flask db upgrade
```

### 2. Start Command（已移除 gevent）
```
gunicorn app:app --bind 0.0.0.0:$PORT --timeout 300 --workers 1 --log-level info --worker-tmp-dir=/dev/shm
```

**注意**：暂时使用同步 worker，不使用 gevent（Python 3.13 不兼容）

### 3. Health Check Path
```
/api/health
```

### 4. Python 版本
- 已在 `runtime.txt` 中指定：`python-3.11.9`
- 如果 Dashboard 允许，手动设置为 Python 3.11

---

## ✅ 已修复

- ✅ 移除了 gevent（Python 3.13 不兼容）
- ✅ 数据库迁移已配置
- ✅ 静态资源路径已修复
- ✅ 代码已推送（commit `4f422b6`）

---

## 🚀 重新部署

设置完成后：
1. 点击 "Save Changes"
2. 点击 "Manual Deploy" → "Deploy latest commit"

应该可以成功部署了！🎉

