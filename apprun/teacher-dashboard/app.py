from flask import Flask, render_template_string, request, redirect, url_for
import requests

app = Flask(__name__)

# 登録された学生URLのリスト（メモリ上に保存）
student_urls = []

HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <title>クラス・ネームボード・ダッシュボード</title>
    <style>
        body { font-family: sans-serif; background-color: #0f172a; color: #f8fafc; padding: 40px; margin: 0; }
        h1 { text-align: center; color: #38bdf8; font-size: 2.5em; margin-bottom: 30px; }
        
        #register-box {
            background: #1e293b; padding: 25px; border-radius: 8px;
            max-width: 600px; margin: 0 auto 40px auto; text-align: center;
            border: 1px solid #334155;
        }
        input[type="url"] { width: 65%; padding: 12px; font-size: 1em; border-radius: 6px; border: 1px solid #475569; background: #0f172a; color: white; }
        button { padding: 12px 24px; font-size: 1em; border-radius: 6px; background: #0284c7; color: white; border: none; cursor: pointer; margin-left: 10px; font-weight: bold; }
        button:hover { background: #0369a1; }

        .board {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
            gap: 25px;
        }
        .card {
            border-radius: 12px; padding: 20px; color: white; text-align: center;
            box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1); position: relative;
            transition: transform 0.2s, box-shadow 0.2s;
        }
        .card:hover { transform: translateY(-5px); box-shadow: 0 10px 15px -3px rgba(0,0,0,0.3); }
        .name { font-size: 1.8em; font-weight: bold; margin: 10px 0; text-shadow: 1px 1px 3px rgba(0,0,0,0.5); }
        .group { font-size: 0.85em; opacity: 0.9; letter-spacing: 1px; }
        
        .status-badge {
            position: absolute; top: 10px; right: 10px; width: 12px; height: 12px; border-radius: 50%;
        }
        .online { background-color: #22c55e; box-shadow: 0 0 8px #22c55e; }
        .offline { background-color: #ef4444; box-shadow: 0 0 8px #ef4444; }
    </style>
    <script>
        // 5秒ごとに画面を自動更新
        setInterval(function(){ location.reload(); }, 5000);
    </script>
</head>
<body>
    <h1>クラス・ネームボード・ダッシュボード</h1>
    
    <div id="register-box">
        <h3 style="margin-top:0; color:#cbd5e1;">自分のAppRun URLを登録</h3>
        <form action="/register" method="post">
            <input type="url" name="url" placeholder="https://xxx.apprun.sakura.ne.jp" required>
            <button type="submit">参加する</button>
        </form>
    </div>

    <div class="board">
        {% for url, info in students.items() %}
        <div class="card" style="background-color: {{ info.color }};">
            <div class="status-badge {% if info.online %}online{% else %}offline{% endif %}"></div>
            <div class="group">{{ info.group }}</div>
            <div class="name">{{ info.name }}</div>
            <div style="font-size: 0.75em; opacity: 0.7; font-family: monospace;">
                {% if info.online %}Active{% else %}Sleeping / Offline{% endif %}
            </div>
        </div>
        {% endfor %}
    </div>
</body>
</html>
"""

@app.route('/')
def index():
    # 画面を開いたタイミングで、登録されている全学生のステータスをリアルタイムに取得
    student_cache = {}
    for url in list(student_urls):
        base_url = url.rstrip('/')
        try:
            # 学生のコンテナに問い合わせ（タイムアウトを1秒にして高速化）
            res = requests.get(f"{base_url}/api/status", timeout=1.0)
            if res.status_code == 200:
                data = res.json()
                student_cache[url] = {
                    "name": data.get("name", "Unknown"),
                    "color": data.get("color", "#475569"),
                    "group": data.get("group", "演習"),
                    "online": True
                }
            else:
                student_cache[url] = {"name": "エラー", "color": "#1e293b", "group": "Error", "online": False}
        except Exception:
            # 相手がスリープ状態（Scale to Zero）などの場合
            student_cache[url] = {"name": "Sleeping...", "color": "#334155", "group": "省電力モード", "online": False}
            
    return render_template_string(HTML_TEMPLATE, students=student_cache)

@app.route('/register', methods=['POST'])
def register():
    url = request.form.get('url', '').strip()
    if url and url.startswith('https://') and url not in student_urls:
        student_urls.append(url)
    return redirect(url_for('index'))

# appオブジェクトをgunicornが認識できるように公開（if __name__ == '__main__' の外に出す）
if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8080)