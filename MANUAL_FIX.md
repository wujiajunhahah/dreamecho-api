# ⚠️ 重要：Render Dashboard 设置

由于 `render.yaml` 可能没有被正确读取，你需要在 **Render Dashboard** 中手动设置：

## 🔧 在 Render Dashboard 中设置：

### 1. 设置 Python 版本
- 进入你的服务设置页面
- 找到 **"Environment"** 或 **"Settings"** 标签
- 找到 **"Python Version"** 或 **"Runtime"** 设置
- 选择 **Python 3.12**

### 2. 更新 Build Command
- 找到 **"Build Command"** 字段
- 改为：
  ```
  pip install --upgrade pip && pip install -r requirements.txt
  ```

### 3. 确保 Start Command 正确
- 找到 **"Start Command"** 字段
- 确保是：
  ```
  gunicorn app:app --bind 0.0.0.0:$PORT --timeout 300 --workers 2
  ```

### 4. 保存并重新部署
- 点击 **"Save Changes"**
- 点击 **"Manual Deploy"** → **"Deploy latest commit"**

---

## ✅ 我已经做的：

1. ✅ 创建了 `runtime.txt` 文件（指定 Python 3.12）
2. ✅ 更新了 `requirements.txt`（Pillow >= 10.3.0）
3. ✅ 代码已推送

---

## 🎯 下一步：

**必须在 Render Dashboard 中手动设置 Python 版本为 3.12！**

设置完成后，重新部署应该就能成功了。

