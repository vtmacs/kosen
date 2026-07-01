#!/usr/bin/env bash
set -euo pipefail

LAB_HOME="${LAB_HOME:-/lab}"

# 任意コマンドが渡された場合はそれを実行して終了（例: docker run image bash）
if [ "$#" -gt 0 ]; then
  exec "$@"
fi

if [ -n "${PORT:-}" ]; then
  # --------------------------------------------------------------------
  # AppRun向け: AppRunはHTTPで待受するコンテナを前提としているため、
  # ttyd でCLIメニューをブラウザ上のターミナルとして公開します。
  # （AppRunのアプリケーション設定で PORT を指定してください。
  #   予約済みのため環境変数として自分で追加設定はできません）
  # --------------------------------------------------------------------
  if command -v ttyd >/dev/null 2>&1; then
    echo "[entrypoint] PORT=${PORT} が設定されています。ttyd経由でラボメニューを公開します。"
    exec ttyd -p "${PORT}" -W bash "${LAB_HOME}/scripts/lab-menu.sh"
  else
    echo "[entrypoint] PORT=${PORT} が設定されていますが、ttydがインストールされていません。" >&2
    echo "[entrypoint] --build-arg INSTALL_TTYD=true でイメージを再ビルドしてください。" >&2
    exit 1
  fi
else
  # --------------------------------------------------------------------
  # ローカル利用向け: docker run -it イメージ名 でそのままメニューを表示
  # --------------------------------------------------------------------
  exec bash "${LAB_HOME}/scripts/lab-menu.sh"
fi
