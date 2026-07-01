#!/usr/bin/env bash
set -euo pipefail

LAB_HOME="${LAB_HOME:-/lab}"

# 任意コマンドが渡された場合はそれを実行して終了（例: docker run image bash）
if [ "$#" -gt 0 ]; then
  exec "$@"
fi

# CLIメニューを使いたい場合は、シェルの中から手動で起動してください:
#   bash /lab/scripts/lab-menu.sh

if [ -n "${PORT:-}" ]; then
  # --------------------------------------------------------------------
  # AppRun向け: AppRunはHTTPで待受するコンテナを前提としているため、
  # ttyd でシェルをブラウザ上のターミナルとして公開します。
  # （AppRunのアプリケーション設定で PORT を指定してください。
  #   予約済みのため環境変数として自分で追加設定はできません）
  #
  # TTYD_USER / TTYD_PASS を環境変数として設定すると、BASIC認証を
  # 有効化します（未設定の場合は認証なしで公開されるため注意）。
  # --------------------------------------------------------------------
  if command -v ttyd >/dev/null 2>&1; then
    echo "[entrypoint] PORT=${PORT} が設定されています。ttyd経由でシェルを公開します。"
    if [ -n "${TTYD_USER:-}" ] && [ -n "${TTYD_PASS:-}" ]; then
      echo "[entrypoint] BASIC認証を有効化しました（ユーザー: ${TTYD_USER}）。"
      exec ttyd -p "${PORT}" -W -c "${TTYD_USER}:${TTYD_PASS}" bash
    else
      echo "[entrypoint] 警告: TTYD_USER/TTYD_PASS が未設定のため、認証なしで公開されます。" >&2
      echo "[entrypoint] 公開環境ではAppRunの環境変数にTTYD_USER/TTYD_PASSの設定を強く推奨します。" >&2
      exec ttyd -p "${PORT}" -W bash
    fi
  else
    echo "[entrypoint] PORT=${PORT} が設定されていますが、ttydがインストールされていません。" >&2
    echo "[entrypoint] --build-arg INSTALL_TTYD=true でイメージを再ビルドしてください。" >&2
    exit 1
  fi
else
  # --------------------------------------------------------------------
  # ローカル利用向け: docker run -it イメージ名 でそのままシェルを表示
  # --------------------------------------------------------------------
  exec bash
fi
