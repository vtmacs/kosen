#!/usr/bin/env bash
set -euo pipefail

#========================
# Config
#========================
UBUNTU_USER="ubuntu"
WWW_DIR="/var/www/html"
TARGET_NAME="mysite.html"
TARGET_FILE="${WWW_DIR}/${TARGET_NAME}"

WATCH_FILE="/usr/share/kadai/prologue.txt"
REPLACEMENT_FILE="/opt/bin/replace.html"
PRESENT_DIR="/opt/bin"
PRESENT_NAME="okinawa.sh"
PRESENT_FILE="${PRESENT_DIR}/${PRESENT_NAME}"

WATCH_SH="/opt/bin/watch.sh"
SHIMA_SH="/etc/shima.sh"
HIDDEN_FILE="/home/${UBUNTU_USER}/.shima"
MSG_TXT="/etc/message.txt"
TAR_OUT="/tmp/sakura.tar.gz"

#========================
# Preconditions
#========================
if [[ $EUID -ne 0 ]]; then
  echo "このスクリプトは root で実行してください（sudo 推奨）。" >&2
  exit 1
fi

id -u "${UBUNTU_USER}" >/dev/null 2>&1 || {
  echo "ユーザ ${UBUNTU_USER} が見つかりません。変数 UBUNTU_USER を修正してください。" >&2
  exit 1
}

# APT: inotify-tools（必要に応じて htop も）
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y inotify-tools htop

# 主要ディレクトリ
mkdir -p /usr/share/kadai
mkdir -p "${PRESENT_DIR}"
mkdir -p "${WWW_DIR}"

#========================
# 1) 初期コンテンツ（mysite.html）
#========================
if [[ ! -f "${TARGET_FILE}" ]]; then
  cat > "${TARGET_FILE}" <<'__HTML__'
<!DOCTYPE html>
<html lang="ja"><meta charset="utf-8">
<title>My Site</title>
<body>
<h1>ようこそ！</h1>
<p>これは元のコンテンツ (mysite.html) です。</p>
</body></html>
__HTML__
  echo "Created ${TARGET_FILE}"
fi

#========================
# 2) prologue.txt（閲覧トリガ）
#========================
cat > "${WATCH_FILE}" <<'TXT'
わたしは怪盗shima
あなたのコンテンツ(mysite.html)は私が預からせてもらったわ
嘘だと思うなら、あなたのコンテンツにブラウザからアクセスしてみることね
TXT
echo "Wrote ${WATCH_FILE}"

#========================
# 3) 差し替えページ replace.html
#========================
cat > "${REPLACEMENT_FILE}" <<'HTML'
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
まずは手始めに、あなたのサーバの `ubuntu` ユーザの
ホームディレクトリ直下にある私のファイルを見つけて。<br>
ただし…そのファイルは「隠しファイル」にしてあるわ。<br>
`ls` を実行しても見つからない。<br>
適切なオプションを使うことね。<br>
インターネットで少し調べればわかるはず。<br>
<br>
あと、ファイルの権限をよく確認することね。<br>
`ubuntu` ユーザのホームディレクトリに置いてあるからって、ファイルに権限があるとは限らないわよ。<br>
<br>
どう？ あなたの知恵と勇気、試させてもらうわね。<br>
それじゃ、次に会えるのを楽しみにしているわ。<br>
隠しファイルの中に、次の指令を書いておいたわ。<br>
<br>
- 怪盗shima 🌹<br>
==================================================<br>
</html>
HTML
echo "Wrote ${REPLACEMENT_FILE}"

#========================
# 4) 隠しファイル /home/ubuntu/.shima
#========================
install -o "${UBUNTU_USER}" -g "${UBUNTU_USER}" -m 000 /dev/null "${HIDDEN_FILE}"
cat > "${HIDDEN_FILE}" <<'TXT'
==================================================
怪盗shimaからのメッセージ
==================================================

おめでとう。このメッセージにたどり着いたのね。
最低限のファイル操作はできるということね。安心したわ。
でも、これはまだ始まりにすぎないわよ。

***** 指令2 *****
次は、サーバ上でシステムが動かしている「プロセス」を確認してもらうわ。
プロセスとは、サーバのCPUやメモリを使って動作しているプログラムやスクリプトのこと。
さあ、`ubuntu` ユーザで htop コマンドを実行してみなさい。
htop
コマンド実行したら、キーボードのqキーを押せば終了できるわよ。

htopは、昔からLinuxで標準的に使われているtopコマンドを直感的にしたプロセスビューアよ。
キーボードの↑↓キーで画面をスクロールして、実行中のプロセスを観察してちょうだい。
どんなプロセスが動いているのか、各プロセスのCPU/メモリ使用率なども、よく見てみるのよ。

私の秘密のスクリプト(shima.sh)をどこかに隠してあるわ。あなたに見つけられるかしら？
ヒントは「秒針が一番高いところに来た時、姿を現す」よ。

スクリプトの場所がわかったら、`ubuntu` ユーザでスクリプトを手動で実行してみなさい。
プロセスビューアのコマンドに表示される通りに実行すればOKよ。
成功すれば、次の指令が表示されるわ。

- 怪盗shima 🌹
==================================================
TXT
chown "${UBUNTU_USER}:${UBUNTU_USER}" "${HIDDEN_FILE}"
chmod 000 "${HIDDEN_FILE}"
echo "Wrote and locked ${HIDDEN_FILE}"

#========================
# 5) /etc/shima.sh と ubuntu の cron（毎分）
#========================
cat > "${SHIMA_SH}" <<'BASH'
#!/usr/bin/env bash
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
BASH
chmod +x "${SHIMA_SH}"

# ubuntu ユーザの crontab に登録（重複防止）
UBU_CRON_LINE="*/1 * * * * ${SHIMA_SH}"
( crontab -u "${UBUNTU_USER}" -l 2>/dev/null | grep -Fv "${UBU_CRON_LINE}"; echo "${UBU_CRON_LINE}" ) \
  | crontab -u "${UBUNTU_USER}" -
echo "Installed ubuntu user's crontab entry for ${SHIMA_SH}"

#========================
# 6) syslog へのヒントと /etc/message.txt
#========================
logger "Notice: 次の指令は /etc/message.txt に残したわ - 怪盗shima"

cat > "${MSG_TXT}" <<'TXT'
==================================================
怪盗shimaからのメッセージ
==================================================

おめでとう。ここまでたどり着くとは見事だわ。
あなたの知恵と努力に、心から感心したわ。

***** 最後の指令 *****
約束通り、あなたのコンテンツを返してあげる。
`/tmp/sakura.tar.gz`に大切に隠しておいたから、取り出してみなさい。

拡張子が`tar.gz`になっているとおり、ファイルは圧縮されているわ。
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
TXT
echo "Wrote ${MSG_TXT}"

#========================
# 7) okinawa.sh（ご褒美コマンド）
#========================
cat > "${PRESENT_FILE}" <<'BASH'
#!/usr/bin/env bash
# 沖縄に関するランダムなメッセージ
messages=(
    "ハイサイ！今日も沖縄の青い海を思い出して元気を出そう！"
    "シーサー曰く：『邪気払いは僕に任せて！』"
    "失敗しても大丈夫！それが学びの近道です！"
    "ゴーヤチャンプルーがあなたの脳をリフレッシュします！"
    "ヤシの木の下で、今日あった嫌なことは忘れちゃおう！"
)

# 沖縄らしいASCIIアート
read -r -d '' ascii_art <<'ART'
  🌴🌴🌴🌴🌴🌴🌴🌴🌴🌴🌴
    シーサー！
     /＼_/＼
   ( o ^ω^ o )
     > ^ ^ <
  🌺🌺🌺🌺🌺🌺🌺🌺🌺🌺🌺
ART

# ランダムにメッセージを選択
random_message=${messages[$RANDOM % ${#messages[@]}]}

# 出力
echo -e "${ascii_art}\n\n${random_message}\n"
BASH
chmod +x "${PRESENT_FILE}"
chown "${UBUNTU_USER}:${UBUNTU_USER}" "${PRESENT_FILE}"
echo "Wrote ${PRESENT_FILE}"

#========================
# 8) 監視スクリプト watch.sh と root の @reboot
#========================
cat > "${WATCH_SH}" <<'BASH'
#!/usr/bin/env bash
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
while read -r path action file; do
    # 指定ファイルがアクセスされた場合
    if [[ "$path$file" == "$WATCH_FILE" ]]; then
        echo "File accessed: $path$file"

        # 1. mysite.html を圧縮して /tmp に移動（okinawa.sh も同梱）
        if [[ -f "$TARGET_FILE" ]]; then
            echo "Compressing and moving $TARGET_FILE..."
            tar cfz "$TEMP_DIR"/sakura.tar.gz -C "$TARGET_DIR" "$TARGET_NAME" -C "$PRESENT_DIR" "$PRESENT_NAME" && rm -f "$TARGET_FILE"
        else
            echo "Warning: $TARGET_FILE does not exist!"
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
BASH
chmod +x "${WATCH_SH}"

# root の @reboot 登録（重複防止）
ROOT_CRON_LINE='@reboot nohup /opt/bin/watch.sh >/var/log/watch_sh.log 2>&1 &'
( crontab -l 2>/dev/null | grep -Fv "${ROOT_CRON_LINE}"; echo "${ROOT_CRON_LINE}" ) | crontab -
echo "Installed root's @reboot for ${WATCH_SH}"

#========================
# 9) 最後に、起動直後の状態を模すため tar を一旦クリア
#========================
# （prologue.txt を開くまでは /tmp/sakura.tar.gz が無い想定）
rm -f "${TAR_OUT}" || true

echo
echo "==== セットアップ完了 ===="
echo "■ 次の手順（学習用）"
echo "1) ブラウザ等で ${TARGET_FILE} を表示（初期ページが見える）"
echo "2) ${WATCH_FILE} を cat 等で“閲覧” → inotify が反応して:"
echo "   - ${TARGET_FILE} を /tmp/sakura.tar.gz に退避（okinawa.sh 同梱）"
echo "   - ${TARGET_FILE} が差し替えられ、メッセージページになる"
echo "3) htop を実行して、毎分の shima.sh 実行を観察（qで終了）"
echo "4) /var/log/syslog（や過去ローテート済み）を cat/grep で検索"
echo "   ヒント: logger によるメッセージが入っています"
echo "5) 最終指令: tar xvfz /tmp/sakura.tar.gz && cp -f mysite.html ${TARGET_FILE} && ./okinawa.sh"
echo
echo "再起動後も watch.sh は自動起動します（root の @reboot）。"
