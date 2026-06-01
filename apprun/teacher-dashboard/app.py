from flask import Flask, render_template_string, request, redirect, url_for
import requests
import time
import threading
import urllib3
from concurrent.futures import ThreadPoolExecutor

app = Flask(__name__)

# 登録された学生URLのリスト（メモリ上に保存）
student_urls = []
# 取得した学生情報のキャッシュ
student_cache = {}
# バックグラウンド処理の実行時間
last_processing_time = 0
# スレッドセーフのためのロック
data_lock = threading.Lock()

# SSL警告を非表示（学生環境の自己署名証明書などへの対策）
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def fetch_student_status(url):
    """学生のコンテナからステータスとContainer IDを高速に取得する共通関数"""
    base_url = url.rstrip('/')
    try:
        # タイムアウトを1秒にして、遅延コンテナによる全体の引きずられを防止
        res = requests.get(f"{base_url}/api/status", timeout=1.0, verify=False)
        if res.status_code == 200:
            data = res.json()
            return {
                "name": data.get("name", "Unknown"),
                "color": data.get("color", "#475569"),
                "group": data.get("group", "演習"),
                "hostname": data.get("hostname", "Unknown ID"),
                "online": True
            }
        else:
            return {"name": "エラー", "color": "#1e293b", "group": "Error", "hostname": "N/A", "online": False}
    except Exception:
        # 相手がスリープ状態（Scale to Zero）などの場合
        return {"name": "Sleeping...", "color": "#334155", "group": "省電力モード", "hostname": "Offline", "online": False}

def monitor_students():
    """バックグラウンドで最大40並列で一斉に学生の状態を確認するスレッド用関数"""
    global last_processing_time
    while True:
        start_time = time.time()
        with data_lock:
            current_urls = list(student_urls)
        
        new_cache_data = {}
        
        # ThreadPoolExecutorにより、全リクエストを並列で一斉送信
        if current_urls:
            with ThreadPoolExecutor(max_workers=40) as executor:
                future_to_url = {executor.submit(fetch_student_status, url): url for url in current_urls}
                for future in future_to_url:
                    url = future_to_url[future]
                    try:
                        new_cache_data[url] = future.result()
                    except Exception:
                        new_cache_data[url] = {"name": "エラー", "color": "#1e293b", "group": "Error", "hostname": "N/A", "online": False}
        
        with data_lock:
            # メモリ上のキャッシュを一括更新
            for url, info in new_cache_data.items():
                student_cache[url] = info
            
            # 登録解除されたURLをキャッシュから削除
            for url in list(student_cache.keys()):
                if url not in current_urls:
                    del student_cache[url]
            
            last_processing_time = time.time() - start_time
        
        time.sleep(5)

# バックグラウンドでの監視スレッドをデーモンとして開始
threading.Thread(target=monitor_students, daemon=True).start()

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
            grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
            gap: 25px;
        }
        .card {
            border-radius: 12px; padding: 20px; color: white; text-align: center;
            box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1); position: relative;
            transition: transform 0.2s, box-shadow 0.2s;
        }
        .card:hover { transform: translateY(-5px); box-shadow: 0 10px 15px -3px rgba(0,0,0,0.3); }
        .name { font-size: 1.8em; font-weight: bold; margin: 8px 0; text-shadow: 1px 1px 3px rgba(0,0,0,0.5); }
        .group { font-size: 0.85em; opacity: 0.9; letter-spacing: 1px; }
        .cid { font-size: 0.75em; opacity: 0.6; font-family: monospace; margin-top: 5px; border-top: 1px solid rgba(255,255,255,0.2); padding-top: 5px; }
        
        .status-badge {
            position: absolute; top: 10px; right: 10px; width: 12px; height: 12px; border-radius: 50%;
        }
        .online { background-color: #22c55e; box-shadow: 0 0 8px #22c55e; }
        .offline { background-color: #ef4444; box-shadow: 0 0 8px #ef4444; }
    </style>
    <script>
        // 5秒ごとに画面を安全に自動同期
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
        {% if processing_time is defined %}
        <p style="margin-top: 15px; font-size: 0.85em; color: #94a3b8;">
            40名規模一斉並列確認時間: {{ "%.2f"|format(processing_time) }} 秒
        </p>
        {% endif %}
    </div>

    <div class="board">
        {% for url, info in students.items() %}
        <div class="card" style="background-color: {{ info.color }};">
            <div class="status-badge {% if info.online %}online{% else %}offline{% endif %}"></div>
            <div class="group">{{ info.group }}</div>
            <div class="name">{{ info.name }}</div>
            <div class="cid">ID: {{ info.hostname }}</div>
        </div>
        {% endfor %}
    </div>
</body>
</html>
"""

@app.route('/')
def index():
    # バックグラウンドスレッドが並列で集めたキャッシュを展開するだけ（超高速応答）
    with data_lock:
        display_cache = dict(student_cache)
        processing_time = last_processing_time
    
    return render_template_string(HTML_TEMPLATE, students=display_cache, processing_time=processing_time)

@app.route('/register', methods=['POST'])
def register():
    url = request.form.get('url', '').strip()
    if url and url.startswith('https://'):
        with data_lock:
            is_new = url not in student_urls
            if is_new:
                student_urls.append(url)
        
        # 新規登録された瞬間だけ、その場でパッと生存確認を行ってUXのガタつきを無くす
        if is_new:
            status_info = fetch_student_status(url)
            with data_lock:
                student_cache[url] = status_info
                
    return redirect(url_for('index'))

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8080)
