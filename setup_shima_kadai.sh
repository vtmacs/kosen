#!/bin/bash

# エラーハンドリング（途中で失敗したら止まる）
set -e

echo "========================================="
echo "  怪盗shimaからの挑戦状 セットアップ開始  "
echo "  (Apache2 既存環境向け)  "
echo "========================================="

# 1. 必要なパッケージのインストール
echo "[1/6] パッケージをインストール中..."
apt-get update -qq
# Apache2はインストール済みのため、inotify-toolsのみインストール
apt-get install -y -qq inotify-tools

# 2. ディレクトリ構造の作成
echo "[2/6] ディレクトリを作成中..."
mkdir -p /opt/bin
mkdir -p /usr/share/kadai
# 既存環境でも念のためディレクトリ存在確認（なければ作成）
mkdir -p /var/www/html

# 3. 資材（ファイル）の配置

echo "[3/6] 各種ファイルを配置中..."

# --- prologue.txt ---
cat <<EOF > /usr/share/kadai/prologue.txt
わたしは怪盗shima
あなたのコンテンツ(mysite.html)は私が預からせてもらったわ
嘘だと思うなら、あなたのコンテンツにブラウザからアクセスしてみることね
EOF

# --- replace.html ---
cat <<EOF > /opt/bin/replace.html
<html lang="ja">
<head>
    <meta charset="UTF-8">
</head>
<body>
==================================================<br>
怪盗shimaからのメッセージ <br>
==================================================<br>
<br>
ごきげんよう。<br>
あなたの大切なコンテンツ、私が預からせてもらったわ。<br>
でも安心して。無意味に奪ったわけじゃないの。<br>
返して欲しいなら、私の「指令」に挑戦してみなさい。<br>
達成できたなら、コンテンツは返してあげる。<br>
<br>
***** 指令1 *****<br>
まずは手始めに、あなたのサーバの \`ubuntu\` ユーザの
ホームディレクトリ直下にある私のファイルを見つけて。<br>
ただし…そのファイルは「隠しファイル」にしてあるわ。<br>
\`ls\` を実行しても見つからない。<br>
適切なオプションを使うことね。<br>
インターネットで少し調べればわかるはず。<br>
<br>
あと、ファイルの権限をよく確認することね。<br>
\`ubuntu\` ユーザのホームディレクトリに置いてあるからって、ファイルに権限があるとは限らないわよ。<br>
<br>
どう？ あなたの知恵と勇気、試させてもらうわね。<br>
それじゃ、次に会えるのを楽しみにしているわ。<br>
隠しファイルの中に、次の指令を書いておいたわ。<br>
<br>
- 怪盗shima 🌹<br>
==================================================<br>

</html>
EOF

# --- .shima (Hidden file) ---
cat <<EOF > /home/ubuntu/.shima
==================================================
怪盗shimaからのメッセージ
==================================================

おめでとう。このメッセージにたどり着いたのね。
最低限のファイル操作はできるということね。安心したわ。
でも、これはまだ始まりにすぎないわよ。

***** 指令2 *****
次は、サーバ上でシステムが動かしている「プロセス」を確認してもらうわ。
プロセスとは、サーバのCPUやメモリを使って動作しているプログラムやスクリプトのこと。
さあ、\`ubuntu\` ユーザで htop コマンドを実行してみなさい。
htop
コマンド実行したら、キーボードのqキーを押せば終了できるわよ。

htopは、昔からLinuxで標準的に使われているtopコマンドを直感的にしたプロセスビューアよ。
キーボードの↑↓キーで画面をスクロールして、実行中のプロセスを観察してちょうだい。
どんなプロセスが動いているのか、各プロセスのCPU/メモリ使用率なども、よく見てみるのよ。

私の秘密のスクリプト(shima.sh)をどこかに隠してあるわ。あなたに見つけられるかしら？
ヒントは「秒針が一番高いところに来た時、姿を現す」よ。

スクリプトの場所がわかったら、\`ubuntu\` ユーザでスクリプトを手動で実行してみなさい。
プロセスビューアのコマンドに表示される通りに実行すればOKよ。
成功すれば、次の指令が表示されるわ。

- 怪盗shima 🌹
==================================================
EOF

# 権限設定 (Userは読めない設定)
chown ubuntu:ubuntu /home/ubuntu/.shima
chmod 000 /home/ubuntu/.shima

# --- shima.sh (Cronで動くスクリプト) ---
cat <<'EOF' > /etc/shima.sh
#!/bin/bash

echo "
==================================================
怪盗shimaからのメッセージ
==================================================

おめでとう。
ふふふ、ここまでたどり着いたのね。
あなたの探究心と努力、少しは認めてあげてもいいわ。 

***** 指令3 *****
次は、サーバ上の「ログ」を確認してもらうわ。
もしサーバに不具合が発生したら、あなたはどうする？
そう、ログファイルを確認して原因を調査し対処する。それが一流のエンジニアとしての第一歩よ。

Linuxでは、「syslog（シスログ）」と呼ばれるシステムログが、/var/log 配下に出力されているわ。
さあ、過去のsyslogファイルを調べてみなさい。
ファイルを確認するには、catコマンドで使うといいわ。

次の指令は、このsyslogの中に書いておいたわ。
見つけられるかしら？期待しているわよ。

- 怪盗shima 🌹
==================================================
"

sleep 15
exit 0
EOF
chmod +x /etc/shima.sh

# --- message.txt (Logヒントの先) ---
cat <<EOF > /etc/message.txt
==================================================
怪盗shimaからのメッセージ
==================================================

おめでとう。ここまでたどり着くとは見事だわ。
あなたの知恵と努力に、心から感心したわ。

***** 最後の指令 *****
約束通り、あなたのコンテンツを返してあげる。
\`/tmp/sakura.tar.gz\`に大切に隠しておいたから、取り出してみなさい。

拡張子が\`tar.gz\`になっているとおり、ファイルは圧縮されているわ。
以下のコマンドで解凍して、ファイルを取り出してね。
tar xvfz /tmp/sakura.tar.gz

解凍が終わったら、lsコマンドで、あなたのコンテンツが取り出せたことを確認すること。
次に、ドキュメントルート配下のコンテンツを差し替えて、ブラウザから表示させてみてね。
cp -f mysite.html /var/www/html/mysite.html

さらに、特別なご褒美として、私が作った沖縄限定のコマンド(okinawa.sh)を一緒に入れておいたわ。
これを実行して、何が起きるか楽しんでちょうだい。
ヒント：何回か繰り返して実行すると、新しい発見があるかもしれないわよ。
./okinawa.sh

それじゃあ、またどこかで会いましょう。
実は、さくらインターネットの沖縄オフィスにも時々顔を出すのよ。
あなたのさらなる成長を楽しみにしているわ。

- 怪盗shima 🌹
==================================================
EOF

# --- okinawa.sh ---
cat <<'EOF' > /opt/bin/okinawa.sh
#!/bin/bash

# 沖縄に関するランダムなメッセージ
messages=(
    "ハイサイ！今日も沖縄の青い海を思い出して元気を出そう！"
    "シーサー曰く：『邪気払いは僕に任せて！』"
    "失敗しても大丈夫！それが学びの近道です！"
    "ゴーヤチャンプルーがあなたの脳をリフレッシュします！"
    "ヤシの木の下で、今日あった嫌なことは忘れちゃおう！"
)

# 沖縄らしいASCIIアート
ascii_art="
  🌴🌴🌴🌴🌴🌴🌴🌴🌴🌴🌴
    シーサー！
      /＼_/＼
    ( o ^ω^ o )
      > ^ ^ <
  🌺🌺🌺🌺🌺🌺🌺🌺🌺🌺🌺
"

# ランダムにメッセージを選択
random_message=${messages[$RANDOM % ${#messages[@]}]}

# 出力
echo -e "$ascii_art\n\n$random_message\n"
EOF
chmod +x /opt/bin/okinawa.sh
chown ubuntu:ubuntu /opt/bin/okinawa.sh

# --- watch.sh (監視スクリプト) ---
cat <<'EOF' > /opt/bin/watch.sh
#!/bin/bash

# 監視対象のファイル
WATCH_FILE="/usr/share/kadai/prologue.txt"

# 差し替え元と差し替え先のパス
TARGET_DIR="/var/www/html"
TARGET_NAME="mysite.html"
PRESENT_DIR="/opt/bin"
PRESENT_NAME="okinawa.sh"

TARGET_FILE=$TARGET_DIR/$TARGET_NAME
TEMP_DIR="/tmp"
REPLACEMENT_FILE="/opt/bin/replace.html"
PRESENT_FILE=$PRESENT_DIR/$PRESENT_NAME

# inotifywaitで監視を開始
inotifywait -m "$(dirname "$WATCH_FILE")" -e access |
while read path action file; do
    # 指定ファイルがアクセスされた場合
    if [[ "$path$file" == "$WATCH_FILE" ]]; then
        echo "File accessed: $path$file"

        # 1. mysite.html を圧縮して /tmp に移動
        if [[ -f "$TARGET_FILE" ]]; then
            echo "Compressing and moving $TARGET_FILE..."
            # tarでまとめる際、絶対パス警告等を避けるため -C を使用
            tar cfz "$TEMP_DIR"/sakura.tar.gz -C "$TARGET_DIR" "$TARGET_NAME" -C "$PRESENT_DIR" "$PRESENT_NAME" && rm -f "$TARGET_FILE"
        else
            echo "Warning: $TARGET_FILE does not exist or already moved!"
        fi

        # 2. 差し替え処理
        if [[ -f "$REPLACEMENT_FILE" ]]; then
            echo "Replacing $TARGET_FILE with $REPLACEMENT_FILE..."
            cp "$REPLACEMENT_FILE" "$TARGET_FILE"
        else
            echo "Error: Replacement file $REPLACEMENT_FILE does not exist!"
        fi
    fi
done
EOF
chmod +x /opt/bin/watch.sh

# --- ダミーのコンテンツ (mysite.html) ---
# 既存ファイルがある場合は上書きしない等の配慮が必要であれば修正してください。
# 今回は演習セットアップのため強制上書きします。
echo "<html lang='ja'><body><h1>ようこそ！これがあなたの元のサイトです。</h1></body></html>" > /var/www/html/mysite.html
chown ubuntu:ubuntu /var/www/html/mysite.html

# 4. Cron設定とログ注入
echo "[4/6] Cronの設定とログの仕込み..."

# rootのcrontabに watch.sh を登録 (@reboot)
if ! crontab -l 2>/dev/null | grep -q "/opt/bin/watch.sh"; then
    (crontab -l 2>/dev/null; echo "@reboot nohup /opt/bin/watch.sh >/dev/null 2>&1 &") | crontab -
fi

# ubuntuユーザのcrontabに shima.sh を登録 (毎分実行)
if ! crontab -u ubuntu -l 2>/dev/null | grep -q "/etc/shima.sh"; then
    (crontab -u ubuntu -l 2>/dev/null; echo "*/1 * * * * /etc/shima.sh") | crontab -u ubuntu -
fi

# syslogにメッセージを注入
logger "Notice: 次の指令は /etc/message.txt に残したわ - 怪盗shima"

# 5. 監視プロセスの起動
echo "[5/6] 監視プロセス(watch.sh)を起動中..."
# 既存プロセスがあればkillしてから起動
pkill -f "/opt/bin/watch.sh" || true
nohup /opt/bin/watch.sh >/dev/null 2>&1 &

echo "========================================="
echo "  セットアップ完了！"
echo "  怪盗shimaが潜伏しました..."
echo "========================================="
echo "開始するには ubuntu ユーザでログインし、以下のファイルにアクセスしてください："
echo "cat /usr/share/kadai/prologue.txt"
