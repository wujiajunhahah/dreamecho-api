from flask import Flask, render_template, request, send_file, jsonify, session, redirect, url_for, flash
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_login import LoginManager, UserMixin, login_user, login_required, logout_user, current_user
from flask_mail import Mail, Message
from flask_bootstrap import Bootstrap
import os
import sys
import json
import time
import requests
import subprocess
import sqlite3
from dotenv import load_dotenv
from tqdm import tqdm
import tenacity
from datetime import datetime
from werkzeug.security import generate_password_hash, check_password_hash
from pathlib import Path
# USD库已移除，现在使用GLB格式
import logging
from logging.handlers import RotatingFileHandler
from werkzeug.utils import secure_filename
import random
import string

# 加载环境变量
load_dotenv()

# API密钥：优先从环境变量读取，如果没有则从config.py读取（用于本地开发）
from config import Config
DEEPSEEK_API_KEY = os.getenv('DEEPSEEK_API_KEY') or Config.DEEPSEEK_API_KEY
TRIPO_API_KEY = os.getenv('TRIPO_API_KEY') or Config.TRIPO_API_KEY

app = Flask(__name__)
app.config.from_object('config.Config')
app.secret_key = os.getenv('SECRET_KEY', os.urandom(24))
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'your-secret-key-here')  # 从环境变量读取

# 数据库配置：支持 Render、Railway 等云平台的 PostgreSQL
DATABASE_URL = os.environ.get('DATABASE_URL')
if DATABASE_URL:
    # Render 等平台使用 postgres://，需要转换为 postgresql://
    if DATABASE_URL.startswith('postgres://'):
        DATABASE_URL = DATABASE_URL.replace('postgres://', 'postgresql://', 1)
    app.config['SQLALCHEMY_DATABASE_URI'] = DATABASE_URL
else:
    # 本地开发使用 SQLite
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///dreams.db'

app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# 初始化扩展
bootstrap = Bootstrap(app)
db = SQLAlchemy(app)
migrate = Migrate(app, db)
login_manager = LoginManager(app)
mail = Mail(app)

# --- 配置 LoginManager ---
login_manager.login_view = 'login'  # 指定登录页面的端点 (route function name)
login_manager.login_message = u"请先登录以访问此页面。"
login_manager.login_message_category = "info"  # 消息类别，用于样式化 (例如 alert-info)
# -------------------------

# 配置日志
if not os.path.exists('logs'):
    os.mkdir('logs')
file_handler = RotatingFileHandler('logs/dream_to_model.log', maxBytes=10240, backupCount=10)
file_handler.setFormatter(logging.Formatter(
    '%(asctime)s %(levelname)s: %(message)s [in %(pathname)s:%(lineno)d]'
))
file_handler.setLevel(logging.INFO)
app.logger.addHandler(file_handler)
app.logger.setLevel(logging.INFO)
app.logger.info('梦境转3D模型应用启动')

# 用户模型
class User(UserMixin, db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(128))
    is_active = db.Column(db.Boolean, default=False)
    is_admin = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    dreams = db.relationship('Dream', backref='user', lazy=True)

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

# 梦境模型
class Dream(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    
    # Form Inputs
    title = db.Column(db.String(150), nullable=False, default="Untitled Dream")
    description = db.Column(db.Text, nullable=True) # Original dream text can go here
    tags = db.Column(db.String(255), nullable=True) # Comma-separated tags
    blockchain = db.Column(db.String(50), nullable=True)
    price = db.Column(db.Float, nullable=True)
    trading_type = db.Column(db.String(50), nullable=True) # e.g., 'fixed', 'auction'
    royalty = db.Column(db.Float, nullable=True) # Royalty percentage
    preview_image = db.Column(db.String(255), nullable=True, default='default_preview.png') # Default preview

    # Generated Data
    dream_text = db.Column(db.Text, nullable=False) # Keep original text
    model_file = db.Column(db.String(255)) # Path to the model file (e.g., .glb, .obj)
    # interpretation_file = db.Column(db.String(255)) # Maybe not needed if storing text?
    keywords = db.Column(db.Text) # JSON string from DeepSeek
    symbols = db.Column(db.Text) # JSON string from DeepSeek
    emotions = db.Column(db.Text) # JSON string from DeepSeek
    visual_description = db.Column(db.Text) # From DeepSeek
    interpretation = db.Column(db.Text) # From DeepSeek
    nft_tx_hash = db.Column(db.String(128), nullable=True) # Store minting transaction hash
    status = db.Column(db.String(50), default='pending') # e.g., pending, processing, complete, minted, failed
    is_public = db.Column(db.Boolean, default=True) # Whether the dream is public
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

@login_manager.user_loader
def load_user(user_id):
    return User.query.get(int(user_id))

class DreamToModelConverter:
    def __init__(self):
        self.deepseek_api_key = DEEPSEEK_API_KEY
        self.tripo_api_key = TRIPO_API_KEY

        if not self.deepseek_api_key:
            print("错误: 未设置DEEPSEEK_API_KEY环境变量")
            sys.exit(1)

        if not self.tripo_api_key:
            print("警告: 未设置TRIPO_API_KEY环境变量，将无法生成3D模型")

    def test_deepseek_api(self):
        """测试 DeepSeek API 是否可用"""
        try:
            response = requests.post(
                "https://api.deepseek.com/v1/chat/completions",
                headers={
                    "Content-Type": "application/json",
                    "Authorization": f"Bearer {self.deepseek_api_key}"
                },
                json={
                    "model": "deepseek-chat",
                    "messages": [
                        {"role": "user", "content": "你好，这是一个测试请求，请回复 '测试成功'"}
                    ],
                    "temperature": 0.3
                },
                timeout=30
            )
            return response.status_code == 200
        except Exception:
            return False

    @tenacity.retry(
        wait=tenacity.wait_fixed(10),  # 每次重试等待10秒
        stop=tenacity.stop_after_attempt(5),  # 最多重试5次
        retry=tenacity.retry_if_exception_type((requests.exceptions.Timeout, requests.exceptions.ConnectionError)),
        reraise=True
    )
    def extract_keywords(self, dream_text):
        """使用DeepSeek API从梦境文本中提取关键词、象征意义和解梦"""
        prompt = f"""
        请分析以下梦境描述，并提取以下内容:
        1. 5-8个最能代表这个梦境的关键词或短语
        2. 3-5个梦境中的核心象征物或场景
        3. 这个梦境可能传达的主要情感或感受
        4. 一个能够视觉化表达这个梦境的简短描述(50字以内)
        5. 对这个梦境的心理学解析(200字以内)

        请以JSON格式返回结果，包含字段: keywords, symbols, emotions, visual_description, interpretation

        梦境描述:
        {dream_text}
        """

        try:
            response = requests.post(
                "https://api.deepseek.com/v1/chat/completions",
                headers={
                    "Content-Type": "application/json",
                    "Authorization": f"Bearer {self.deepseek_api_key}"
                },
                json={
                    "model": "deepseek-chat",
                    "messages": [
                        {"role": "system", "content": "你是一个专业的梦境分析师，擅长提取梦境中的关键元素和象征意义。请直接返回JSON格式的结果，不要添加任何Markdown格式。"},
                        {"role": "user", "content": prompt}
                    ],
                    "temperature": 0.3
                },
                timeout=90  # 增加超时时间至90秒
            )

            if response.status_code != 200:
                raise Exception(f"DeepSeek API 调用失败，状态码: {response.status_code}")

            result = response.json()
            content = result["choices"][0]["message"]["content"]

            # 从Markdown中提取JSON
            json_content = self.extract_json_from_markdown(content)

            # 手动解析 JSON，确保兼容性
            analysis = json.loads(json_content)

            # 验证返回字段
            required_fields = ["keywords", "symbols", "emotions", "visual_description", "interpretation"]
            for field in required_fields:
                if field not in analysis:
                    raise Exception(f"DeepSeek API 返回缺少字段: {field}")

            return analysis

        except requests.exceptions.Timeout:
            raise
        except Exception as e:
            raise

    def extract_json_from_markdown(self, text):
        """从Markdown文本中提取JSON"""
        import re
        json_match = re.search(r'```(?:json)?\s*([\s\S]*?)\s*```', text)

        if json_match:
            return json_match.group(1)
        else:
            cleaned_text = text.strip()
            if cleaned_text.startswith("```") and cleaned_text.endswith("```"):
                cleaned_text = cleaned_text[3:-3].strip()
            return cleaned_text

    def generate_model_prompt(self, analysis):
        """根据分析结果生成3D模型提示词"""
        symbols = ", ".join(analysis["symbols"])
        emotions = ", ".join(analysis["emotions"])
        model_prompt = f"{analysis['visual_description']} 包含 {symbols}. 整体氛围: {emotions}"
        return model_prompt

    def generate_3d_model(self, model_prompt):
        """使用Tripo API生成3D模型"""
        try:
            # 创建任务
            response = requests.post(
                "https://api.tripo3d.ai/v2/openapi/task",
                headers={
                    "Content-Type": "application/json",
                    "Authorization": f"Bearer {self.tripo_api_key}"
                },
                json={
                    "type": "text_to_model",
                    "prompt": model_prompt
                },
                timeout=30
            )

            if response.status_code != 200:
                return None

            result = response.json()
            task_id = result.get("data", {}).get("task_id")
            if not task_id:
                return None

            # 轮询任务状态
            model_url = None
            max_attempts = 60
            for attempt in range(max_attempts):
                time.sleep(10)
                status_response = requests.get(
                    f"https://api.tripo3d.ai/v2/openapi/task/{task_id}",
                    headers={"Authorization": f"Bearer {self.tripo_api_key}"},
                    timeout=30
                )

                if status_response.status_code != 200:
                    continue

                status_data = status_response.json()
                task_status = status_data.get("data", {}).get("status")

                if task_status == "success":
                    data = status_data.get("data", {})
                    output = data.get("output", {})
                    result = data.get("result", {})

                    model_url = (
                        output.get("pbr_model") or
                        output.get("model") or
                        result.get("pbr_model", {}).get("url") or
                        result.get("model", {}).get("url")
                    )

                    if not model_url:
                        return None

                    break
                elif task_status in ["failed", "cancelled", "unknown"]:
                    return None

            if not model_url:
                return None

            # 下载模型文件
            model_response = requests.get(model_url, stream=True, timeout=30)
            filename = f"dream_model_{int(time.time())}.glb"
            with open(filename, "wb") as f:
                for chunk in model_response.iter_content(chunk_size=1024):
                    if chunk:
                        f.write(chunk)

            return filename

        except Exception:
            return None

    def process_dream(self, dream_text, user_id, dream_id=None):
        """处理梦境并生成3D模型"""
        try:
            app.logger.info(f'开始处理用户 {user_id} 的梦境')
            
            # 如果提供了dream_id，则初始化进度跟踪
            if dream_id:
                update_dream_progress(dream_id, "开始", 5, 20, "正在启动梦境处理...")
            
            # 测试 DeepSeek API 可用性
            if not self.test_deepseek_api():
                app.logger.error('DeepSeek API 不可用')
                if dream_id:
                    update_dream_progress(dream_id, "失败", 0, 0, "API服务暂时不可用，请稍后再试")
                raise Exception("DeepSeek API 服务暂时不可用，请稍后再试")

            # 提取关键词和分析
            app.logger.info('开始提取关键词和分析')
            if dream_id:
                update_dream_progress(dream_id, "分析梦境", 20, 15, "正在提取关键词和进行梦境分析...")
            analysis = self.extract_keywords(dream_text)
            
            # 生成3D模型
            app.logger.info('开始生成3D模型')
            if dream_id:
                update_dream_progress(dream_id, "生成模型", 40, 10, "正在生成3D模型...")
            model_prompt = self.generate_model_prompt(analysis)
            model_url = self.generate_3d_model(model_prompt)
            
            if not model_url:
                app.logger.error('3D模型生成失败')
                if dream_id:
                    update_dream_progress(dream_id, "失败", 0, 0, "3D模型生成失败，请稍后重试")
                raise Exception("3D模型生成失败，请稍后重试")

            # 创建用户目录
            user_dir = os.path.join('static', 'models', f'user_{user_id}')
            os.makedirs(user_dir, exist_ok=True)
            
            # 下载模型文件
            app.logger.info('下载模型文件')
            if dream_id:
                update_dream_progress(dream_id, "下载模型", 60, 5, "正在下载生成的模型文件...")
            model_filename = f"dream_{int(time.time())}.glb"  # 使用GLB格式
            model_path = os.path.join(user_dir, model_filename)
            
            response = requests.get(model_url, stream=True)
            if response.status_code != 200:
                if dream_id:
                    update_dream_progress(dream_id, "失败", 0, 0, "下载模型文件失败")
                raise Exception("下载模型文件失败")
            
            total_size = int(response.headers.get('content-length', 0))
            block_size = 1024
            
            with open(model_path, 'wb') as f, tqdm(
                desc="下载模型",
                total=total_size,
                unit='iB',
                unit_scale=True,
                unit_divisor=1024,
            ) as pbar:
                for data in response.iter_content(block_size):
                    size = f.write(data)
                    pbar.update(size)
            
            # 优化模型处理
            if dream_id:
                update_dream_progress(dream_id, "优化处理", 80, 3, "正在优化模型和处理资源...")
            
            # 构建相对路径
            relative_model_path = os.path.join('models', f'user_{user_id}', model_filename)
            
            # 返回结果字典
            result = {
                'model_path': relative_model_path,
                'keywords': json.dumps(analysis['keywords']),
                'symbols': json.dumps(analysis['symbols']),
                'emotions': json.dumps(analysis['emotions']),
                'visual_description': analysis['visual_description'],
                'interpretation': analysis['interpretation']
            }
            
            app.logger.info(f'梦境处理完成，模型路径: {relative_model_path}')
            return result
            
        except Exception as e:
            app.logger.error(f'处理梦境时发生错误: {str(e)}')
            # 更新失败状态
            if dream_id:
                update_dream_progress(dream_id, "失败", 0, 0, f"处理失败: {str(e)}")
            raise

# GLB转换函数已移除，现在直接使用GLB格式

@app.cli.command("create-admin")
def create_admin():
    """创建管理员账号"""
    admin = User(
        username='123',
        email='123@example.com',
        is_active=True,
        is_admin=True
    )
    admin.set_password('123')
    db.session.add(admin)
    db.session.commit()
    print('测试账号创建成功！用户名和密码都是：123')

# 路由：首页
@app.route('/')
def index():
    """首页"""
    try:
        # 获取最新的一些模型用于展示
        recent_models = Dream.query.filter_by(is_public=True).order_by(Dream.created_at.desc()).limit(6).all()
        return render_template('index_modern.html', recent_models=recent_models)
    except Exception as e:
        app.logger.error(f"首页加载错误: {str(e)}")
        return render_template('index_modern.html', recent_models=[])

# 路由：创建梦境页面
@app.route('/create_dream', methods=['GET', 'POST'])
@login_required
def create_dream():
    """创造梦境页面"""
    if request.method == 'POST':
        try:
            # 获取表单数据
            dream_title = request.form.get('dream_title', '').strip()
            dream_description = request.form.get('dream_description', '').strip()
            dream_mood = request.form.get('dream_mood', '')
            dream_style = request.form.get('dream_style', '')
            blockchain = request.form.get('blockchain', '')
            initial_price = request.form.get('initial_price', type=float)
            royalty = request.form.get('royalty', type=float)
            is_public = 'is_public' in request.form
            
            # 验证必填字段
            if not dream_title or not dream_description or not blockchain:
                flash('请填写所有必填字段', 'error')
                return render_template('create_dream_modern.html')
            
            if len(dream_description) < 50:
                flash('梦境描述至少需要50个字符', 'error')
                return render_template('create_dream_modern.html')
            
            # 创建新的梦境模型
            new_model = Dream(
                title=dream_title,
                description=dream_description,
                mood=dream_mood,
                style=dream_style,
                blockchain=blockchain,
                initial_price=initial_price or 0.1,
                royalty=royalty or 2.5,
                is_public=is_public,
                user_id=current_user.id,
                status='processing'
            )
            
            db.session.add(new_model)
            db.session.commit()
            
            # 这里可以添加异步任务来生成3D模型
            # 暂时设置为已完成状态
            new_model.status = 'completed'
            new_model.model_url = f'/static/models/dream_{new_model.id}.glb'
            new_model.image_url = f'/static/images/dream_{new_model.id}.jpg'
            db.session.commit()
            
            flash('梦境创造成功！', 'success')
            return redirect(url_for('model_detail', model_id=new_model.id))
            
        except Exception as e:
            app.logger.error(f"创造梦境错误: {str(e)}")
            flash('创造梦境时发生错误，请重试', 'error')
            return render_template('create_dream_modern.html')
    
    return render_template('create_dream_modern.html')

# 全局进度跟踪字典
# 结构: {dream_id: {'stage': 'stage_name', 'progress': percentage, 'remaining_minutes': minutes, 'status': 'status_message'}}
dream_progress = {}

# 更新进度的辅助函数
def update_dream_progress(dream_id, stage, progress, remaining_minutes, status=None):
    """
    更新指定梦境ID的生成进度
    
    :param dream_id: 梦境ID
    :param stage: 当前处理阶段
    :param progress: 百分比进度 (0-100)
    :param remaining_minutes: 预计剩余分钟数
    :param status: 可选的状态消息
    """
    dream_progress[dream_id] = {
        'stage': stage,
        'progress': progress,
        'remaining_minutes': remaining_minutes,
        'status': status or "正在处理中..."
    }

@app.route('/api/progress/<dream_id>', methods=['GET'])
def get_progress(dream_id):
    """
    获取模型生成进度
    """
    # 检查梦境ID是否存在
    try:
        dream_id = int(dream_id)
    except ValueError:
        return jsonify({"success": False, "error": "无效的梦境ID"}), 400
    
    # 查找数据库中的梦境记录
    dream = Dream.query.get(dream_id)
    if not dream:
        return jsonify({"success": False, "error": "梦境不存在"}), 404
    
    # 检查进度记录是否存在
    if dream_id not in dream_progress:
        # 如果记录不存在但梦境状态为完成
        if dream.status == 'complete':
            return jsonify({
                "success": True,
                "stage": "完成",
                "progress": 100,
                "remaining_minutes": 0,
                "status": "您的梦境模型已生成完成！"
            })
        # 如果记录不存在且梦境状态为失败
        elif dream.status == 'failed':
            return jsonify({
                "success": False,
                "stage": "失败",
                "progress": 0,
                "status": "模型生成失败，请重试。"
            }), 500
        # 如果记录不存在但梦境还在处理中
        elif dream.status == 'processing':
            # 创建一个初始进度记录
            update_dream_progress(dream_id, "分析梦境", 10, 15, "正在分析您的梦境描述...")
        # 如果记录不存在且梦境状态为等待
        else:  # pending
            update_dream_progress(dream_id, "等待处理", 0, 20, "您的请求已加入队列，即将开始处理...")
    
    # 返回进度信息
    progress_data = dream_progress.get(dream_id, {
        "stage": "未知",
        "progress": 0,
        "remaining_minutes": 0,
        "status": "无法获取进度信息"
    })
    
    return jsonify({
        "success": True,
        **progress_data
    })

# 路由：创建梦境 API
@app.route('/api/dreams/create', methods=['POST'])
@login_required
def create_dream_api():
    """创建新的梦境记录 API"""
    try:
        # 从表单获取数据
        title = request.form.get('title', 'Untitled Dream')
        description = request.form.get('description')
        tags = request.form.get('tags')
        blockchain = request.form.get('blockchain')
        price_str = request.form.get('price')
        trading_type = request.form.get('tradingType')
        royalty_str = request.form.get('royalty')

        if not description:
            return jsonify({'success': False, 'error': '梦境描述不能为空'}), 400
        
        # 数据类型转换和验证
        price = None
        if price_str:
            try:
                price = float(price_str)
            except ValueError:
                return jsonify({'success': False, 'error': '价格必须是数字'}), 400
        
        royalty = None
        if royalty_str:
            try:
                royalty = float(royalty_str)
            except ValueError:
                return jsonify({'success': False, 'error': '版税必须是数字'}), 400

        # 创建初始梦境记录
        new_dream = Dream(
            user_id=current_user.id,
            title=title,
            description=description,
            dream_text=description,
            tags=tags,
            blockchain=blockchain,
            price=price,
            trading_type=trading_type,
            royalty=royalty,
            status='pending'
        )
        db.session.add(new_dream)
        db.session.commit()
        
        dream_id = new_dream.id
        app.logger.info(f"创建了新梦境记录，ID: {dream_id}")
        
        # 初始化进度
        update_dream_progress(dream_id, "等待处理", 0, 20, "您的请求已加入队列，即将开始处理...")
        
        # 异步处理（实际应用中应使用Celery或其他任务队列）
        # 这里为了简化，我们使用一个简单的线程
        import threading
        
        def process_dream_async(description, user_id, dream_id):
            try:
                # 更新状态为处理中
                dream = Dream.query.get(dream_id)
                dream.status = 'processing'
                db.session.commit()
                
                # 创建转换器实例并处理梦境
                converter = DreamToModelConverter()
                result = converter.process_dream(dream_text=description, user_id=user_id, dream_id=dream_id)
                
                # 更新梦境记录
                if result and 'model_path' in result:
                    dream.model_file = result['model_path']
                    dream.keywords = result.get('keywords', '')
                    dream.symbols = result.get('symbols', '')
                    dream.emotions = result.get('emotions', '')
                    dream.visual_description = result.get('visual_description', '')
                    dream.interpretation = result.get('interpretation', '')
                    dream.status = 'complete'
                    db.session.commit()
                    
                    # 更新最终进度
                    update_dream_progress(dream_id, "完成", 100, 0, "您的梦境模型已生成完成！")
                    app.logger.info(f"梦境 {dream_id} 处理完成")
                else:
                    raise Exception("模型生成失败")
                    
            except Exception as e:
                app.logger.error(f"异步处理梦境 {dream_id} 失败: {str(e)}")
                # 更新状态为失败
                dream = Dream.query.get(dream_id)
                dream.status = 'failed'
                db.session.commit()
                
                # 更新进度为失败状态
                update_dream_progress(dream_id, "失败", 0, 0, f"模型生成失败: {str(e)}")
        
        # 启动异步处理
        threading.Thread(target=process_dream_async, args=(description, current_user.id, dream_id)).start()
        
        return jsonify({
            'success': True,
            'dream_id': dream_id,
            'message': '梦境创建请求已提交！'
        })
            
    except Exception as e:
        app.logger.error(f"创建梦境API失败: {str(e)}")
        return jsonify({'success': False, 'error': f'服务器错误: {str(e)}'}), 500

# 路由：个人中心
@app.route('/profile')
@login_required
def profile():
    """个人中心页面"""
    return render_template('profile.html')

# 路由：设置页面
@app.route('/settings')
@login_required
def settings():
    """设置页面"""
    return render_template('settings.html')

# 路由：联系我们
@app.route('/contact')
def contact():
    return render_template('contact.html')

# 路由：常见问题
@app.route('/faq')
def faq():
    return render_template('faq.html')

# 路由：隐私政策
@app.route('/privacy')
def privacy():
    return render_template('privacy.html')

# 路由：获取解释
@app.route('/api/interpretation/<model_name>')
@login_required
def get_interpretation(model_name):
    # 从模型文件名中提取梦境ID
    dream_id = model_name.split('.')[0]
    
    # 获取梦境数据
    dream = Dream.query.filter_by(id=dream_id).first()
    if not dream:
        return jsonify({'error': '梦境不存在'}), 404
    
    # 检查权限
    if dream.user_id != current_user.id:
        return jsonify({'error': '没有权限访问'}), 403
    
    # 返回解析数据
    return jsonify({
        'keywords': dream.keywords.split(','),
        'symbols': dream.symbols.split(','),
        'emotions': dream.emotions.split(','),
        'visuals': dream.visual_description,
        'psychology': dream.interpretation
    })

# 错误处理
@app.errorhandler(404)
def page_not_found(e):
    return render_template('404.html'), 404

@app.errorhandler(500)
def internal_error(error):
    db.session.rollback()
    app.logger.error(f'服务器错误: {error}')
    return render_template('500.html'), 500

@app.errorhandler(413)
def too_large(error):
    app.logger.error(f'文件过大: {request.url}')
    return render_template('413.html'), 413

@app.route('/model_library')
def model_library():
    # 示例模型数据
    models = [
        {
            'id': 1,
            'title': '梦境巴士',
            'tags': ['交通工具', '城市', '公共空间'],
            'description': '这是一个充满未来感的巴士模型，展现了城市交通的现代化愿景。模型细节丰富，完美呈现了未来城市交通工具的设计理念。',
            'price': 0.5,
            'model_path': '/static/models/大巴.glb'
        },
        {
            'id': 2,
            'title': 'Kanye',
            'tags': ['人物', '艺术', '音乐'],
            'description': '这个模型展现了说唱歌手Kanye West的独特形象，捕捉了他标志性的表情和姿态。模型通过精细的细节刻画，完美展现了艺术家的个性特征。',
            'price': 0.8,
            'model_path': '/static/models/kanye.glb'
        },
        {
            'id': 3,
            'title': '未命名扫描',
            'tags': ['扫描', '实验', '艺术'],
            'description': '这是一个通过3D扫描技术创建的实验性艺术作品。模型展现了扫描过程中捕捉到的独特纹理和形态，呈现出一种介于现实与虚拟之间的视觉效果。',
            'price': 0.3,
            'model_path': '/static/models/Untitled_Scan.glb'
        }
    ]
    return render_template('model_library.html', models=models)

@app.route('/model/<model_id>')
def model_detail(model_id):
    """
    显示模型详情页面
    """
    # 在实际应用中，这里应该从数据库中获取模型信息
    # 现在我们使用模拟的数据
    model = {
        'id': model_id,
        'title': '梦境模型 #' + str(model_id),
        'creator': '梦想家',
        'creation_date': datetime.now().strftime('%Y-%m-%d %H:%M'),
        'price': 0.05,
        'currency': 'ETH',
        'tags': ['奇幻', '抽象', '色彩'],
        'description': '这个模型代表了一个梦境场景，由AI根据梦境描述自动生成。',
        'model_path': f'static/models/dream_model_{model_id}.glb',
        'technical_info': {
            'polygons': random.randint(10000, 50000),
            'vertices': random.randint(5000, 25000),
            'format': 'glTF/GLB'
        }
    }
    
    return render_template('model_detail.html', model=model)

@app.route('/api/mint_nft/<model_id>', methods=['POST'])
#@login_required # 如果需要登录才能铸造，取消注释这行
def mint_nft_api(model_id):
    """模拟 NFT 铸造 API"""
    try:
        # 1. 验证模型是否存在 (如果从数据库获取)
        # model = Dream.query.get(model_id)
        # if not model:
        #     return jsonify({'success': False, 'error': '模型不存在'}), 404
        # if model.user_id != current_user.id: # 验证所有权
        #     return jsonify({'success': False, 'error': '无权操作'}), 403
        # if model.nft_tx_hash: # 检查是否已铸造
        #     return jsonify({'success': False, 'error': '该模型已被铸造'}), 400
        
        app.logger.info(f"开始模拟为模型 ID {model_id} 铸造 NFT")
        
        # 2. 模拟区块链交互延迟
        time.sleep(random.uniform(3, 8)) # 模拟 3-8 秒的处理时间
        
        # 3. 模拟成功/失败 (例如，80% 成功率)
        if random.random() < 0.8:
            # 模拟生成交易哈希
            fake_tx_hash = '0x' + ''.join(random.choices(string.ascii_lowercase + string.digits, k=64))
            app.logger.info(f"模型 ID {model_id} NFT 铸造模拟成功，交易哈希: {fake_tx_hash}")
            
            # 4. 更新数据库状态 (如果从数据库获取)
            # model.nft_tx_hash = fake_tx_hash
            # model.status = 'minted'
            # db.session.commit()
            
            return jsonify({'success': True, 'tx_hash': fake_tx_hash})
        else:
            app.logger.error(f"模型 ID {model_id} NFT 铸造模拟失败")
            error_message = random.choice(["网络拥堵，请稍后重试", "Gas 费不足", "合约调用失败"])
            return jsonify({'success': False, 'error': error_message}), 500

    except Exception as e:
        app.logger.error(f"铸造 NFT 时发生意外错误 (模型 ID: {model_id}): {str(e)}")
        return jsonify({'success': False, 'error': '服务器内部错误，请联系管理员'}), 500

@app.route('/project_background')
def project_background():
    """项目背景页面"""
    return render_template('project_background.html')

@app.route('/style-guide')
def style_guide():
    """渲染设计系统样式指南页面"""
    return render_template('style_guide.html')

@app.route('/about')
def about():
    """渲染项目背景页面"""
    return render_template('about.html')

@app.route('/api/generate_tags', methods=['POST'])
def generate_tags():
    """使用AI生成梦境标签"""
    data = request.get_json()
    description = data.get('description')
    
    # 这里调用Deep Seek API进行标签生成
    # 目前使用模拟数据
    tags = ['梦境', '飞翔', '自由', '探索', '冒险', '奇幻']
    
    return jsonify({
        'success': True,
        'tags': tags
    })

@app.route('/my_dreams')
@login_required
def my_dreams():
    dreams = Dream.query.filter_by(user_id=current_user.id).all()
    return render_template('my_dreams.html', dreams=dreams)

@app.route('/login', methods=['GET', 'POST'])
def login():
    """登录页面"""
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        remember = request.form.get('remember', False)
        
        user = User.query.filter_by(username=username).first()
        if user and user.check_password(password):
            login_user(user, remember=remember)
            flash('登录成功', 'success')
            next_page = request.args.get('next')
            if next_page:
                return redirect(next_page)
            return redirect(url_for('index'))
        flash('用户名或密码错误', 'danger')
    
    return render_template('login.html')

@app.route('/register', methods=['GET', 'POST'])
def register():
    """注册页面"""
    if request.method == 'POST':
        username = request.form.get('username')
        email = request.form.get('email')
        password = request.form.get('password')
        
        if User.query.filter_by(username=username).first():
            flash('用户名已存在', 'danger')
            return redirect(url_for('register'))
        
        if User.query.filter_by(email=email).first():
            flash('邮箱已被使用', 'danger')
            return redirect(url_for('register'))
        
        user = User(username=username, email=email)
        user.set_password(password)
        
        db.session.add(user)
        db.session.commit()
        
        flash('注册成功，请登录', 'success')
        return redirect(url_for('login'))
    
    return render_template('register.html')

if __name__ == '__main__':
    # 支持云平台的 PORT 环境变量（Render、Railway等）
    port = int(os.environ.get('PORT', 5001))
    debug = os.environ.get('FLASK_ENV') != 'production'
    app.run(host='0.0.0.0', port=port, debug=debug)

# ========== iOS App API Endpoints ==========

import uuid
from functools import wraps

def token_required(f):
    """Token认证装饰器"""
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            try:
                token = auth_header.split(' ')[1]  # Bearer <token>
            except:
                pass
        
        if not token:
            return jsonify({'message': 'Token缺失'}), 401
        
        # 简单验证：在实际应用中应该验证JWT token
        # 这里暂时使用session验证
        if not current_user.is_authenticated:
            return jsonify({'message': 'Token无效'}), 401
        
        return f(*args, **kwargs)
    return decorated

@app.route('/api/health', methods=['GET'])
def health_check():
    """健康检查，验证DeepSeek和Tripo API状态"""
    converter = DreamToModelConverter()
    deepseek_ok = converter.test_deepseek_api()
    tripo_ok = bool(TRIPO_API_KEY)  # 简单检查API key是否存在
    
    return jsonify({
        'deepseek': 'ok' if deepseek_ok else 'error',
        'tripo': 'ok' if tripo_ok else 'error'
    })

@app.after_request
def after_request(response):
    """添加CORS头，支持iOS应用跨域请求"""
    response.headers.add('Access-Control-Allow-Origin', '*')
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
    response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS')
    return response

@app.route('/api/auth/login', methods=['POST', 'OPTIONS'])
def api_login():
    """iOS应用登录API"""
    if request.method == 'OPTIONS':
        return '', 200
    try:
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')
        
        if not email or not password:
            return jsonify({'error': '邮箱和密码不能为空'}), 400
        
        user = User.query.filter_by(email=email).first()
        if user and user.check_password(password):
            login_user(user)
            # 生成简单的token（实际应用中应使用JWT）
            token = str(uuid.uuid4())
            session['api_token'] = token
            
            return jsonify({
                'user': {
                    'id': str(user.id),
                    'username': user.username,
                    'email': user.email
                },
                'token': token
            })
        else:
            return jsonify({'error': '邮箱或密码错误'}), 401
    except Exception as e:
        app.logger.error(f"登录API错误: {str(e)}")
        return jsonify({'error': '服务器错误'}), 500

@app.route('/api/auth/register', methods=['POST', 'OPTIONS'])
def api_register():
    """iOS应用注册API"""
    if request.method == 'OPTIONS':
        return '', 200
    try:
        data = request.get_json()
        username = data.get('username')
        email = data.get('email')
        password = data.get('password')
        
        if not username or not email or not password:
            return jsonify({'error': '所有字段都是必填的'}), 400
        
        if User.query.filter_by(username=username).first():
            return jsonify({'error': '用户名已存在'}), 400
        
        if User.query.filter_by(email=email).first():
            return jsonify({'error': '邮箱已被使用'}), 400
        
        user = User(username=username, email=email)
        user.set_password(password)
        
        db.session.add(user)
        db.session.commit()
        
        login_user(user)
        token = str(uuid.uuid4())
        session['api_token'] = token
        
        return jsonify({
            'user': {
                'id': str(user.id),
                'username': user.username,
                'email': user.email
            },
            'token': token
        }), 201
    except Exception as e:
        app.logger.error(f"注册API错误: {str(e)}")
        db.session.rollback()
        return jsonify({'error': '服务器错误'}), 500

@app.route('/api/session', methods=['GET'])
@login_required
def api_session():
    """获取当前会话信息"""
    return jsonify({
        'user': {
            'id': str(current_user.id),
            'username': current_user.username,
            'email': current_user.email
        },
        'token': session.get('api_token', '')
    })

@app.route('/api/dreams', methods=['GET'])
@login_required
def api_get_dreams():
    """获取用户的梦境列表"""
    try:
        dreams = Dream.query.filter_by(user_id=current_user.id).all()
        dreams_list = []
        
        for dream in dreams:
            # 映射后端状态到iOS应用期望的状态
            status_mapping = {
                'pending': 'pending',
                'processing': 'processing',
                'complete': 'completed',
                'completed': 'completed',
                'failed': 'failed'
            }
            dream_status = status_mapping.get(dream.status or 'pending', 'pending')
            
            dream_dict = {
                'id': str(dream.id),
                'title': dream.title,
                'description': dream.description or dream.dream_text or '',
                'status': dream_status,
                'tags': dream.tags.split(',') if dream.tags else [],
                'createdAt': dream.created_at.isoformat() if dream.created_at else datetime.utcnow().isoformat(),
                'updatedAt': dream.updated_at.isoformat() if dream.updated_at else datetime.utcnow().isoformat(),
                'previewImageURL': dream.image_url if dream.image_url else None,
                'modelURL': dream.model_file if dream.model_file else None
            }
            dreams_list.append(dream_dict)
        
        return jsonify(dreams_list)
    except Exception as e:
        app.logger.error(f"获取梦境列表错误: {str(e)}")
        return jsonify({'error': '服务器错误'}), 500

@app.route('/api/dreams', methods=['POST'])
@login_required
def api_create_dream():
    """创建新梦境 - 调用真实的DeepSeek和Tripo API"""
    try:
        data = request.get_json()
        title = data.get('title', 'Untitled Dream')
        description = data.get('description', '')
        style = data.get('style', '')
        mood = data.get('mood', '')
        tags = data.get('tags', [])
        
        if not description:
            return jsonify({'error': '梦境描述不能为空'}), 400
        
        new_dream = Dream(
            user_id=current_user.id,
            title=title,
            description=description,
            dream_text=description,
            style=style,
            mood=mood,
            tags=','.join(tags) if tags else None,
            status='pending'
        )
        
        db.session.add(new_dream)
        db.session.commit()
        
        # 异步处理梦境生成 - 这里会调用真实的DeepSeek和Tripo API
        import threading
        threading.Thread(target=process_dream_async, args=(description, current_user.id, new_dream.id)).start()
        
        dream_response = {
            'id': str(new_dream.id),
            'title': new_dream.title,
            'description': new_dream.description,
            'status': new_dream.status,
            'tags': tags,
            'createdAt': new_dream.created_at.isoformat(),
            'updatedAt': new_dream.updated_at.isoformat()
        }
        
        return jsonify(dream_response), 201
    except Exception as e:
        app.logger.error(f"创建梦境错误: {str(e)}")
        db.session.rollback()
        return jsonify({'error': '服务器错误'}), 500

@app.route('/api/dreams/<dream_id>', methods=['GET'])
@login_required
def api_get_dream(dream_id):
    """获取单个梦境详情"""
    try:
        try:
            dream_id_int = int(dream_id)
        except ValueError:
            return jsonify({'error': '无效的梦境ID'}), 400
            
        dream = Dream.query.filter_by(id=dream_id_int, user_id=current_user.id).first()
        if not dream:
            return jsonify({'error': '梦境不存在'}), 404
        
        return jsonify({
            'id': str(dream.id),
            'title': dream.title,
            'description': dream.description or dream.dream_text or '',
            'status': 'completed' if dream.status == 'complete' else dream.status or 'pending',
            'tags': dream.tags.split(',') if dream.tags else [],
            'createdAt': dream.created_at.isoformat() if dream.created_at else datetime.utcnow().isoformat(),
            'updatedAt': dream.updated_at.isoformat() if dream.updated_at else datetime.utcnow().isoformat(),
            'previewImageURL': dream.image_url if dream.image_url else None,
            'modelURL': dream.model_file if dream.model_file else None
        })
    except Exception as e:
        app.logger.error(f"获取梦境详情错误: {str(e)}")
        return jsonify({'error': '服务器错误'}), 500

def process_dream_async(description, user_id, dream_id):
    """异步处理梦境生成"""
    try:
        dream = Dream.query.get(dream_id)
        dream.status = 'processing'
        db.session.commit()
        
        converter = DreamToModelConverter()
        result = converter.process_dream(dream_text=description, user_id=user_id, dream_id=dream_id)
        
        if result and 'model_path' in result:
            dream.model_file = result['model_path']
            dream.status = 'complete'  # 数据库使用complete
            db.session.commit()
    except Exception as e:
        app.logger.error(f"异步处理梦境失败: {str(e)}")
        dream = Dream.query.get(dream_id)
        dream.status = 'failed'
        db.session.commit()

@app.route('/api/dreams/<dream_id>/events', methods=['GET'])
@login_required
def api_dream_events(dream_id):
    """流式事件端点，用于实时推送梦境生成进度"""
    try:
        try:
            dream_id_int = int(dream_id)
        except ValueError:
            return jsonify({'error': '无效的梦境ID'}), 400
        
        dream = Dream.query.filter_by(id=dream_id_int, user_id=current_user.id).first()
        if not dream:
            return jsonify({'error': '梦境不存在'}), 404
        
        # 简单的SSE实现
        def generate():
            import time
            progress_stages = [
                (0.1, 'pending', '正在排队...'),
                (0.3, 'processing', '正在分析梦境...'),
                (0.6, 'processing', '正在生成3D模型...'),
                (0.9, 'processing', '正在优化模型...'),
                (1.0, 'completed', '模型生成完成！')
            ]
            
            for progress, status, message in progress_stages:
                yield f"data: {{\"status\": \"{status}\", \"progress\": {progress}, \"message\": \"{message}\"}}\n\n"
                time.sleep(1)  # 模拟处理时间
        
        from flask import Response
        return Response(generate(), mimetype='text/event-stream')
    except Exception as e:
        app.logger.error(f"流式事件错误: {str(e)}")
        return jsonify({'error': '服务器错误'}), 500
