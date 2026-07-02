#!/usr/bin/env bash
# tmuxで永続セッションに入る。何らかの理由でtmuxが使えない/失敗した場合でも、
# 必ず素のbashにフォールバックし、画面が真っ黒のまま固まらないようにする。
#
# bashrcの自動読み込み（対話シェル判定・ログインシェル判定）に依存すると
# 環境によって効いたり効かなかったりするため、--rcfile と -i を明示指定して
# 確実に bashrc-lab（プロンプト設定）を読み込ませる。

BASHRC="${INFRA_HOME:-/opt/lab-infra}/bashrc-lab"

cd "${LAB_HOME:-/lab}" || true

echo "[start-shell] whoami: $(whoami)"
echo "[start-shell] pwd: $(pwd)"
echo "[start-shell] HOME: ${HOME:-未設定}"
echo "[start-shell] bashrc: ${BASHRC} ($([ -f "$BASHRC" ] && echo '存在します' || echo '見つかりません'))"
echo "[start-shell] tmux path: $(command -v tmux || echo '見つかりません')"

if command -v tmux >/dev/null 2>&1; then
  echo "[start-shell] tmuxセッション 'lab' にアタッチ/新規作成します..."
  tmux new-session -A -s lab "bash --rcfile '${BASHRC}' -i"
  tmux_status=$?
  echo "[start-shell] tmuxが終了しました (exit code: ${tmux_status})。bashにフォールバックします。"
else
  echo "[start-shell] tmuxが見つからないため、bashを直接起動します。"
fi

exec bash --rcfile "${BASHRC}" -i
