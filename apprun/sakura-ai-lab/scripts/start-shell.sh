#!/usr/bin/env bash
# tmuxで永続セッションに入る。何らかの理由でtmuxが使えない/失敗した場合でも、
# 必ず素のbashにフォールバックし、画面が真っ黒のまま固まらないようにする。

echo "[start-shell] whoami: $(whoami)"
echo "[start-shell] pwd: $(pwd)"
echo "[start-shell] HOME: ${HOME:-未設定}"
echo "[start-shell] tmux path: $(command -v tmux || echo '見つかりません')"

if command -v tmux >/dev/null 2>&1; then
  echo "[start-shell] tmuxセッション 'lab' にアタッチ/新規作成します..."
  tmux new-session -A -s lab
  tmux_status=$?
  echo "[start-shell] tmuxが終了しました (exit code: ${tmux_status})。bashにフォールバックします。"
else
  echo "[start-shell] tmuxが見つからないため、bashを直接起動します。"
fi

exec bash
