#!/bin/bash

# エラーで停止させる
set -e

echo "========================"
echo "  怪盗shimaからの挑戦状  "
echo "========================"

# 1. パッケージインストール
echo "[1/6] パッケージ確認..."
apt-get update -qq
apt-get install -y -qq inotify-tools

# 2. ディレクトリ作成
mkdir -p /opt/bin
mkdir -p /usr/share/kadai
mkdir -p /var/www/html

# 3. ファイル作成 (echoで1行ずつ作成)

echo "[3/6] ファイル生成中..."

# --- prologue.txt ---
TARGET="/usr/share/kadai/prologue.txt"
echo "わたしは怪盗shima" > "$TARGET"
echo "あなたのコンテンツ(mysite.html)は私が預からせてもらったわ" >> "$TARGET"
echo "嘘だと思うなら、あなたのコンテンツにブラウザからアクセスしてみることね" >> "$TARGET"

# --- replace.html ---
TARGET="/opt/bin/replace.html"
echo '<!DOCTYPE html>' > "$TARGET"
echo '<html lang="ja"><head><meta charset="UTF-8"></head><body>' >> "$TARGET"
echo '==================================================<br>' >> "$TARGET"
echo '怪盗shimaからのメッセージ <br>' >> "$TARGET"
echo '==================================================<br><br>' >> "$TARGET"
echo 'ごきげんよう。<br>あなたの大切なコンテンツ、私が預からせてもらったわ。<br>' >> "$TARGET"
echo '***** 指令1 *****<br>' >> "$TARGET"
echo 'まずは手始めに、あなたのサーバの `ubuntu` ユーザのホームディレクトリ直下にある私のファイルを見つけて。<br>' >> "$TARGET"
echo 'ただし…そのファイルは「隠しファイル」にしてあるわ。<br>' >> "$TARGET"
echo '<br>どう？ あなたの知恵と勇気、試させてもらうわね。<br>' >> "$TARGET"
echo '- 怪盗shima 🌹<br>' >> "$TARGET"
echo '</body></html>' >> "$TARGET"

# --- .shima ---
TARGET="/home/ubuntu/.shima"
echo "==================================================" > "$TARGET"
echo "怪盗shimaからのメッセージ" >> "$TARGET"
echo "==================================================" >> "$TARGET"
echo "" >> "$TARGET"
echo "おめでとう。隠しファイルを見つけたのね。" >> "$TARGET"
echo "" >> "$TARGET"
echo "***** 指令2 *****" >> "$TARGET"
echo "次は、サーバ上でシステムが動かしている「プロセス」を確認してもらうわ。" >> "$TARGET"
echo "ubuntu ユーザで htop コマンドを実行して、私のスクリプト(shima.sh)を探しなさい。" >> "$TARGET"
echo "ヒントは「秒針が一番高いところに来た時、姿を現す」よ。" >> "$TARGET"
echo "見つけたら手動で実行してみることね。" >> "$TARGET"
echo "" >> "$TARGET"
echo "- 怪盗shima 🌹" >> "$TARGET"
echo "==================================================" >> "$TARGET"

chown ubuntu:ubuntu "$TARGET"
chmod 000 "$TARGET"

# --- shima.sh ---
TARGET="/etc/shima.sh"
echo '#!/bin/bash' > "$TARGET"
echo 'echo ""' >> "$TARGET"
echo 'echo "=================================================="' >> "$TARGET"
echo 'echo "怪盗shimaからのメッセージ"' >> "$TARGET"
echo 'echo "=================================================="' >> "$TARGET"
echo 'echo ""' >> "$TARGET"
echo 'echo "***** 指令3 *****"' >> "$TARGET"
echo 'echo "次は、サーバ上の「ログ」を確認してもらうわ。"' >> "$TARGET"
echo 'echo "/var/log/syslog を確認して、私からのメッセージを探しなさい。"' >> "$TARGET"
echo 'echo "- 怪盗shima 🌹"' >> "$TARGET"
echo 'echo "=================================================="' >> "$TARGET"
# 表示時間は30秒
echo 'sleep 30' >> "$TARGET"
echo 'exit 0' >> "$TARGET"

chmod +x "$TARGET"

# --- message.txt ---
TARGET="/etc/message.txt"
echo "==================================================" > "$TARGET"
echo "怪盗shimaからのメッセージ" >> "$TARGET"
echo "==================================================" >> "$TARGET"
echo "" >> "$TARGET"
echo "***** 最後の指令 *****" >> "$TARGET"
echo "約束通り、あなたのコンテンツを返してあげる。" >> "$TARGET"
echo "/tmp/sakura.tar.gz に隠しておいたから、以下のコマンドで解凍しなさい。" >> "$TARGET"
echo "tar xvfz /tmp/sakura.tar.gz" >> "$TARGET"
echo "その後、mysite.html を /var/www/html にコピーして戻すのよ。" >> "$TARGET"
echo "" >> "$TARGET"
echo "ご褒美に ./okinawa.sh も実行してみてね。" >> "$TARGET"
echo "- 怪盗shima 🌹" >> "$TARGET"
echo "==================================================" >> "$TARGET"

# --- okinawa.sh (修正版) ---
TARGET="/opt/bin/okinawa.sh"
echo '#!/bin/bash' > "$TARGET"
echo '' >> "$TARGET"
echo '# 沖縄に関するランダムなメッセージ' >> "$TARGET"
echo 'messages=(' >> "$TARGET"
echo '    "ハイサイ！今日も沖縄の青い海を思い出して元気を出そう！"' >> "$TARGET"
echo '    "シーサー曰く：『邪気払いは僕に任せて！』"' >> "$TARGET"
echo '    "失敗しても大丈夫！それが学びの近道です！"' >> "$TARGET"
echo '    "ゴーヤチャンプルーがあなたの脳をリフレッシュします！"' >> "$TARGET"
echo '    "ヤシの木の下で、今日あった嫌なことは忘れちゃおう！"' >> "$TARGET"
echo ')' >> "$TARGET"
echo '' >> "$TARGET"
echo '# 沖縄らしいASCIIアート' >> "$TARGET"
echo 'ascii_art="' >> "$TARGET"
echo '  🌴🌴🌴🌴🌴🌴🌴🌴🌴🌴🌴' >> "$TARGET"
echo '    シーサー！' >> "$TARGET"
echo '      /＼_/＼' >> "$TARGET"
echo '    ( o ^ω^ o )' >> "$TARGET"
echo '      > ^ ^ <' >> "$TARGET"
echo '  🌺🌺🌺🌺🌺🌺🌺🌺🌺🌺🌺' >> "$TARGET"
echo '"' >> "$TARGET"
echo '' >> "$TARGET"
echo '# ランダムにメッセージを選択' >> "$TARGET"
echo 'random_message=${messages[$RANDOM % ${#messages[@]}]}' >> "$TARGET"
echo '' >> "$TARGET"
echo '# 出力' >> "$TARGET"
echo 'echo -e "$ascii_art\n\n$random_message\n"' >> "$TARGET"

chmod +x "$TARGET"
chown ubuntu:ubuntu "$TARGET"

# --- watch.sh ---
TARGET="/opt/bin/watch.sh"
echo '#!/bin/bash' > "$TARGET"
echo 'WATCH_FILE="/usr/share/kadai/prologue.txt"' >> "$TARGET"
echo 'TARGET_FILE="/var/www/html/mysite.html"' >> "$TARGET"
echo 'TEMP_DIR="/tmp"' >> "$TARGET"
echo 'REPLACE="/opt/bin/replace.html"' >> "$TARGET"
echo '' >> "$TARGET"
echo '# inotifywait execution' >> "$TARGET"
echo 'inotifywait -m "$(dirname "$WATCH_FILE")" -e access |' >> "$TARGET"
echo 'while read path action file; do' >> "$TARGET"
echo '    if [[ "$path$file" == "$WATCH_FILE" ]]; then' >> "$TARGET"
echo '        echo "Trap triggered!"' >> "$TARGET"
echo '        if [[ -f "$TARGET_FILE" ]]; then' >> "$TARGET"
echo '            tar cfz "$TEMP_DIR/sakura.tar.gz" -C /var/www/html mysite.html -C /opt/bin okinawa.sh' >> "$TARGET"
echo '            rm -f "$TARGET_FILE"' >> "$TARGET"
echo '        fi' >> "$TARGET"
echo '        cp "$REPLACE" "$TARGET_FILE"' >> "$TARGET"
echo '    fi' >> "$TARGET"
echo 'done' >> "$TARGET"

chmod +x "$TARGET"

# --- mysite.html ---
echo "<html lang='ja'><body><h1>Welcome! Original Site</h1></body></html>" > /var/www/html/mysite.html
chown ubuntu:ubuntu /var/www/html/mysite.html

# 4. Cron設定とログ注入
echo "[4/6] Cron & Log 設定..."

# 既存のCronジョブ重複登録防止
crontab -l 2>/dev/null | grep -v "/opt/bin/watch.sh" | crontab -
crontab -u ubuntu -l 2>/dev/null | grep -v "/etc/shima.sh" | crontab -u ubuntu -

# 新規登録
(crontab -l 2>/dev/null; echo "@reboot nohup /opt/bin/watch.sh >/dev/null 2>&1 &") | crontab -
(crontab -u ubuntu -l 2>/dev/null; echo "*/1 * * * * /etc/shima.sh") | crontab -u ubuntu -

# 5. プロセス起動
echo "[5/6] 監視開始..."
pkill -f "/opt/bin/watch.sh" || true
nohup /opt/bin/watch.sh >/dev/null 2>&1 &
logger "Notice: 次の指令は /etc/message.txt に残したわ - 怪盗shima"

echo "========================================="
echo "  セットアップ完了！"
echo "========================================="
echo "ubuntu ユーザで以下を実行してスタート："
echo "cat /usr/share/kadai/prologue.txt"
