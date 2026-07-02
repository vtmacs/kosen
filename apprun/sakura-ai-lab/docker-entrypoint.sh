#!/usr/bin/env bash
set -euo pipefail

LAB_HOME="${LAB_HOME:-/lab}"
INFRA_HOME="${INFRA_HOME:-/opt/lab-infra}"
START_SHELL="${INFRA_HOME}/start-shell.sh"

# 任意コマンドが渡された場合はそれを実行して終了（例: docker run image bash）
if [ "$#" -gt 0 ]; then
  exec "$@"
fi

# CLIメニューを使いたい場合は、シェルの中から手動で起動してください:
#   bash /opt/lab-infra/lab-menu.sh

if [ -n "${PORT:-}" ]; then
  # --------------------------------------------------------------------
  # AppRun向け: AppRunはHTTPで待受するコンテナを前提としているため、
  # ttyd でシェルをブラウザ上のターミナルとして公開します。
  # start-shell.sh 経由で起動するため、tmuxが何らかの理由で失敗しても
  # 必ずbashにフォールバックします（黒画面のまま固まるのを防ぐため）。
  #
  # TTYD_USER / TTYD_PASS を環境変数として設定すると、BASIC認証を
  # 有効化します（未設定の場合は認証なしで公開されるため注意）。
  # --------------------------------------------------------------------
  if command -v ttyd >/dev/null 2>&1; then
    echo "[entrypoint] PORT=${PORT} が設定されています。ttyd経由でシェルを公開します。"
    if [ -n "${TTYD_USER:-}" ] && [ -n "${TTYD_PASS:-}" ]; then
      echo "[entrypoint] BASIC認証を有効化しました（ユーザー: ${TTYD_USER}）。"
      exec ttyd -p "${PORT}" -W -c "${TTYD_USER}:${TTYD_PASS}" bash "${START_SHELL}"
    else
      echo "[entrypoint] 警告: TTYD_USER/TTYD_PASS が未設定のため、認証なしで公開されます。" >&2
      echo "[entrypoint] 公開環境ではAppRunの環境変数にTTYD_USER/TTYD_PASSの設定を強く推奨します。" >&2
      exec ttyd -p "${PORT}" -W bash "${START_SHELL}"
    fi
  else
    echo "[entrypoint] PORT=${PORT} が設定されていますが、ttydがインストールされていません。" >&2
    echo "[entrypoint] --build-arg INSTALL_TTYD=true でイメージを再ビルドしてください。" >&2
    exit 1
  fi
else
  # --------------------------------------------------------------------
  # ローカル利用向け: docker run -it イメージ名 でそのままstart-shell.shに入る
  # --------------------------------------------------------------------
  exec bash "${START_SHELL}"
fi
