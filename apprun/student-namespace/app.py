from flask import Flask, jsonify, render_template_string
import os
import socket

app = Flask(__name__)

# 環境変数から設定を取得（デフォルト値を設定）
MY_NAME = os.getenv('MY_NAME', '未設定の学生')
MY_COLOR = os.getenv('MY_COLOR', '#334155') # デフォルトは落ち着いたグレー
MY_GROUP = os.getenv('MY_GROUP', '高専演習')

# 画面表示用のHTMLテンプレート
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <title>{{ name }}'s Board</title>
    <style>
        body {
            font-family: sans-serif;
            background-color: #f1f5f9;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
        }
        .card {
            background-color: white;
            border-radius: 12px;
            box-shadow: 0 10px 25px rgba(0,0,0,0.1);
            overflow: hidden;
            width: 320px;
            text-align: center;
            border: 1px solid #e2e8f0;
        }
        .color-band {
            background-color: {{ color }};
            height: 120px;
            width: 100%;
            transition: background-color 0.5s;
        }
        .content {
            padding: 25px;
        }
        .group { color: #64748b; font-size: 0.9em; text-transform: uppercase; letter-spacing: 1px; margin: 0; }
        h1 { margin: 10px 0; font-size: 2.2em; color: #1e293b; }
        .meta { font-size: 0.75em; color: #94a3b8; margin-top: 20px; font-family: monospace; }
    </style>
</head>
<body>
    <div class="card">
        <div class="color-band"></div>
        <div class="content">
            <p class="group">{{ group }}</p>
            <h1>{{ name }}</h1>
            <p class="meta">Container ID: {{ hostname }}</p>
        </div>
    </div>
</body>
</html>
"""

# 1. ブラウザ表示用
@app.route('/')
def index():
    return render_template_string(HTML_TEMPLATE, name=MY_NAME, color=MY_COLOR, group=MY_GROUP, hostname=socket.gethostname())

# 2. 親サイト（アグリゲーター）からのデータ収集用API
@app.route('/api/status')
def status():
    return jsonify({
        "name": MY_NAME,
        "color": MY_COLOR,
        "group": MY_GROUP,
        "hostname": socket.gethostname()
    })

if __name__ == "__main__":
    # AppRunの要求に合わせて8080ポートでリッスン
    app.run(host='0.0.0.0', port=8080)
