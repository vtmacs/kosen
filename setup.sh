#!/bin/bash
#
# 演習用まとめ設定スクリプト（Ubuntu Server 24.04 向け）
# 以下の処理を自動で行います：
#   - CPU暴走スクリプト設置と systemd サービス設定
#   - 巨大ダミーログファイル作成（fallocate による 10GB）
#   - ログ肥大化スクリプト設置（常に 10GB を再割り当て）
#   - トラップスクリプト設置と cron 登録（3分おき）
#   - ubuntu ユーザーが root 権限でも crontab を実行できないよう sudoers を設定
#
# 実行方法:
#   sudo bash setup.sh
#
# 注意: 演習専用サーバで実行してください。

set -e

# root 権限チェック
if [ "$(id -u)" -ne 0 ]; then
  echo "エラー: このスクリプトは root で実行してください。"
  exit 1
fi

# 1. CPU暴走スクリプト(thunder.sh) とサービス(thunder.service) 設定
THUNDER_SCRIPT="/usr/local/bin/thunder.sh"
cat > "${THUNDER_SCRIPT}" << 'EOF'
#!/bin/bash
# thunder.sh: CPU を常時 100% 使用させる無限ループ
while true; do
  :
done
EOF
chmod +x "${THUNDER_SCRIPT}"

THUNDER_SERVICE="/etc/systemd/system/thunder.service"
cat > "${THUNDER_SERVICE}" << 'EOF'
[Unit]
Description=Thunder Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/thunder.sh
Restart=no

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start thunder.service

# 2. 巨大ログファイルの初回作成 (fallocate で 10GB を割り当て)
HUGE_LOG="/var/log/huge_app.log"
if [ ! -e "${HUGE_LOG}" ]; then
  fallocate -l 10G "${HUGE_LOG}"
fi

# 3. ログ肥大化スクリプト(log_flood.sh) 設定（常に 10GB 再割り当て）
LOG_FLOOD_SCRIPT="/usr/local/bin/log_flood.sh"
cat > "${LOG_FLOOD_SCRIPT}" << 'EOF'
#!/bin/bash
# log_flood.sh: /var/log/syslog と huge_app.log に大量ログを吐き出す
HUGE_LOG="/var/log/huge_app.log"

# 常に 10GB を再割り当て
fallocate -l 10G "${HUGE_LOG}"

# ダミーログ出力
for i in {1..100}; do
  logger "Dummy log line \$i"
  echo "\$(date '+%Y-%m-%d %H:%M:%S') Dummy log line \$i" | tee -a "${HUGE_LOG}" > /dev/null
done
EOF
chmod +x "${LOG_FLOOD_SCRIPT}"

# 4. トラップスクリプト(evil.sh) 設定
EVIL_SCRIPT="/usr/local/bin/evil.sh"
cat > "${EVIL_SCRIPT}" << 'EOF'
#!/bin/bash
# evil.sh: thunder.service を再起動し、ログ肥大化を行う
systemctl restart thunder.service
/usr/local/bin/log_flood.sh
EOF
chmod +x "${EVIL_SCRIPT}"

# 5. cron 登録 (3分おきに evil.sh を実行)
EXISTING_CRON=$(sudo crontab -u root -l 2>/dev/null || true)
CRON_JOB="*/3 * * * * /usr/local/bin/evil.sh"
if ! echo "${EXISTING_CRON}" | grep -q "/usr/local/bin/evil.sh"; then
  {
    echo "${EXISTING_CRON}"
    echo "${CRON_JOB}"
  } | sudo crontab -u root -
fi

# 6. ubuntu ユーザーが root 権限でも crontab を実行できないよう設定
SUDOERS_FILE="/etc/sudoers.d/no-crontab-ubuntu"
cat > "${SUDOERS_FILE}" << 'EOF'
# ubuntu ユーザーは crontab コマンドを禁止
Cmnd_Alias CRONTAB = /usr/bin/crontab
ubuntu ALL=(ALL) ALL, !CRONTAB
EOF
chmod 440 "${SUDOERS_FILE}"
visudo -c -q

echo "セットアップが完了しました。"
