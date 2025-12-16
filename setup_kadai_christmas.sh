#!/bin/bash

# エラーで停止させる
set -e

echo "========================="
echo "  怪盗shimaからの挑戦状   "
echo " (クリスマスバージョンV2) "
echo "========================="

# 1. パッケージインストール
echo "[1/3] パッケージ確認..."
apt-get update -qq
apt-get install -y -qq inotify-tools

# 2. ファイル作成
echo "[2/3] ファイル生成中..."

#  ディレクトリ作成
mkdir -p /opt/bin
mkdir -p /usr/share/kadai
mkdir -p /var/www/html

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

chown ubuntu:www-data "$TARGET"

# --- .shima ---
TARGET="/home/ubuntu/.shima"
echo "==================================================" > "$TARGET"
echo "怪盗shimaからのメッセージ" >> "$TARGET"
echo "==================================================" >> "$TARGET"
echo "" >> "$TARGET"
echo "おめでとう。隠しファイルを見つけたのね。" >> "$TARGET"
echo "" >> "$TARGET"
echo "***** 指令2 *****" >> "$TARGET"
echo "次は、サーバ上でこっそり動き続けている「不審なプロセス」を見つけてもらうわ。" >> "$TARGET"
echo "プロセスとは、実行中のプログラムのことよ。" >> "$TARGET"
echo "" >> "$TARGET"
echo "以下のコマンドを実行して、現在動いているすべてのプロセスを表示しなさい。" >> "$TARGET"
echo "ps -ef" >> "$TARGET"
echo "" >> "$TARGET"
echo "ものすごい量の文字が出てきたでしょう？" >> "$TARGET"
echo "この中から、私の名前がついたスクリプト(shima.sh)を探し出すのよ。" >> "$TARGET"
echo "見つけるのが大変なら、grepコマンドと組み合わせて絞り込んでみなさい。" >> "$TARGET"
echo "例： ps -ef | grep shima" >> "$TARGET"
echo "" >> "$TARGET"
echo "見つけたら、そのスクリプトのパス（場所）を確認して、手動で実行してみることね。" >> "$TARGET"
echo "" >> "$TARGET"
echo "- 怪盗shima 🌹" >> "$TARGET"
echo "==================================================" >> "$TARGET"

chown ubuntu:ubuntu "$TARGET"
chmod 000 "$TARGET"

# --- shima.sh ---
TARGET="/etc/shima.sh"
echo '#!/bin/bash' > "$TARGET"
echo '' >> "$TARGET"
echo '# 手動実行(端末接続)された場合のみメッセージを表示して終了' >> "$TARGET"
echo 'if [ -t 1 ]; then' >> "$TARGET"
echo '  echo ""' >> "$TARGET"
echo '  echo "=================================================="' >> "$TARGET"
echo '  echo "怪盗shimaからのメッセージ"' >> "$TARGET"
echo '  echo "=================================================="' >> "$TARGET"
echo '  echo ""' >> "$TARGET"
echo '  echo "***** 指令3 *****"' >> "$TARGET"
echo '  echo "よくぞ私を見つけたわね。"' >> "$TARGET"
echo '  echo "次は、サーバ上の「ログ」を確認してもらうわ。"' >> "$TARGET"
echo '  echo "/var/log/syslog を確認して、私からのメッセージを探しなさい。"' >> "$TARGET"
echo '  echo "- 怪盗shima 🌹"' >> "$TARGET"
echo '  echo "=================================================="' >> "$TARGET"
echo '  exit 0' >> "$TARGET"
echo 'fi' >> "$TARGET"
echo '' >> "$TARGET"
echo '# 自動実行(バックグラウンド)の場合は無限ループで常駐' >> "$TARGET"
echo 'while true; do' >> "$TARGET"
echo '  sleep 60' >> "$TARGET"
echo 'done' >> "$TARGET"

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
echo "ご褒美に ./christmas.sh も実行してみてね。" >> "$TARGET"
echo "- 怪盗shima 🌹" >> "$TARGET"
echo "==================================================" >> "$TARGET"

# --- christmas.sh (派手なバージョン) ---
TARGET="/opt/bin/christmas.sh"
# 複雑な内容になるため、ヒアドキュメントで生成
cat << 'EOF' > "$TARGET"
#!/bin/bash

# ==============================================
# christmas.sh
# クリスマスツリーのアニメーションを表示するスクリプト
# ==============================================

# 終了時(Ctrl+Cなど)に実行する処理
cleanup() {
    tput cnorm # カーソルを表示に戻す
    exit 0
}
trap cleanup INT TERM EXIT

# カーソルを隠す（アニメーションを綺麗に見せるため）
tput civis

# --- 色の定義 ---
RED="\033[1;31m"    # 赤
GREEN="\033[1;32m"  # 緑
YELLOW="\033[1;33m" # 黄
BLUE="\033[1;34m"   # 青
WHITE="\033[1;37m"  # 白
BROWN="\033[0;33m"  # 茶
NC="\033[0m"        # リセット

# 画面クリア
clear

# --- アニメーションループ (約15秒間) ---
for i in {1..30}; do
    # 偶数回と奇数回で飾りの色パターンを切り替え（点滅効果）
    if [ $((i % 2)) -eq 0 ]; then
        C1="${RED}"; C2="${BLUE}"; C3="${YELLOW}"; STAR_C="${WHITE}"
    else
        C1="${YELLOW}"; C2="${RED}"; C3="${BLUE}"; STAR_C="${YELLOW}"
    fi

    # カーソルをホーム位置（左上）に戻して上書き描画
    tput home

    printf "\n"
    # 星
    printf "          ${STAR_C}★${NC}\n"
    
    # 1段目
    printf "         ${GREEN}/${NC}${C1}o${NC}${GREEN}\\\\${NC}\n"
    
    # 2段目
    printf "        ${GREEN}/${NC}${C2}*${NC}${GREEN} ${NC}${C3}+${NC}${GREEN}\\\\${NC}\n"
    
    # 3段目
    printf "       ${GREEN}/${NC}${C3}+${NC}${GREEN} ${NC}${C1}o${NC}${GREEN} ${NC}${C2}*${NC}${GREEN}\\\\${NC}\n"
    
    # 4段目
    printf "      ${GREEN}/${NC}${C1}o${NC}${GREEN} ${NC}${C2}*${NC}${GREEN} ${NC}${C3}+${NC}${GREEN} ${NC}${C1}o${NC}${GREEN}\\\\${NC}\n"
    
    # 5段目
    printf "     ${GREEN}/${NC}${C2}*${NC}${GREEN} ${NC}${C3}+${NC}${GREEN} ${NC}${C1}o${NC}${GREEN} ${NC}${C2}*${NC}${GREEN} ${NC}${C3}+${NC}${GREEN}\\\\${NC}\n"
    
    # 最下部
    printf "    ${GREEN}/___________${NC}${GREEN}\\\\${NC}\n"
    
    # 幹 (アンダースコア3個分)
    printf "        ${BROWN}|   |${NC}\n"
    printf "        ${BROWN}|___|${NC}\n"
    printf "\n"
    printf "    ${RED}Merry Christmas!!${NC}    \n"
    printf "\n"

    sleep 0.5
done

# 終了処理
cleanup
EOF

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
echo '' >> "$TARGET"
echo '        # バックアップがまだ存在しない場合のみ作成する（上書き防止）' >> "$TARGET"
echo '        if [[ ! -f "$TEMP_DIR/sakura.tar.gz" ]] && [[ -f "$TARGET_FILE" ]]; then' >> "$TARGET"
echo '            tar cfz "$TEMP_DIR/sakura.tar.gz" -C /var/www/html mysite.html -C /opt/bin christmas.sh' >> "$TARGET"
echo '        fi' >> "$TARGET"
echo '' >> "$TARGET"
echo '        rm -f "$TARGET_FILE"' >> "$TARGET"
echo '        cp "$REPLACE" "$TARGET_FILE"' >> "$TARGET"
echo '        chown ubuntu:www-data "$TARGET_FILE"' >> "$TARGET"
echo '    fi' >> "$TARGET"
echo 'done' >> "$TARGET"

chmod +x "$TARGET"

# --- mysite.html ---
TARGET="/var/www/html/mysite.html"
echo "mysite.html の確認..."
if [ ! -f "$TARGET" ]; then
    echo "  -> 既存のファイルが見つかりません。ダミーを作成します。"
    echo '<!DOCTYPE html>' > "$TARGET"
    echo '<html lang="ja">' >> "$TARGET"
    echo '<head><meta charset="UTF-8"><title>Christmas Party 2024</title></head>' >> "$TARGET"
    echo '<body style="background-color: #0f4d19; color: white; text-align: center;">' >> "$TARGET"
    echo '<h1>🎄 Christmas Party 2024 🎄</h1>' >> "$TARGET"
    echo '<p>今年のクリスマスパーティーのお知らせです！</p>' >> "$TARGET"
    echo '<p>日時：12月25日 19:00〜</p>' >> "$TARGET"
    echo '<p>場所：我が家</p>' >> "$TARGET"
    echo '<p>プレゼント交換会もあるよ🎁</p>' >> "$TARGET"
    echo '</body></html>' >> "$TARGET"
else
    echo "  -> 既存のファイルを使用します。"
fi

chown ubuntu:www-data "$TARGET"

# 3. プロセス起動
echo "[3/3] 監視プロセス & ターゲットプロセス起動..."

# watch.sh 起動
pkill -f "/opt/bin/watch.sh" || true
nohup /opt/bin/watch.sh >/dev/null 2>&1 &

# shima.sh 起動
pkill -f "/etc/shima.sh" || true
# ubuntuユーザ権限でバックグラウンド実行
sudo -u ubuntu nohup /etc/shima.sh >/dev/null 2>&1 &

# ログ注入
logger "Notice: 次の指令は /etc/message.txt に残したわ - 怪盗shima"

echo "========================================="
echo "  セットアップ完了！"
echo "========================================="
echo "ubuntu ユーザで以下を実行してスタート："
echo "cat /usr/share/kadai/prologue.txt"
