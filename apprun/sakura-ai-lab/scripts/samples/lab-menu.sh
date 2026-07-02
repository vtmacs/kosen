#!/usr/bin/env bash
set -euo pipefail
cd "${LAB_HOME:-/lab}/samples"

banner() {
  cat <<'EOF'
==========================================================
 さくらのAI検定：AI実践 ラボ環境
 さくらのAI Engine ハンズオン CLI メニュー
==========================================================
EOF
}

pause() {
  echo
  read -rp "Enterキーでメニューに戻る..." _ || true
}

menu() {
  banner
  cat <<'EOF'
  1) チャット補完 (chat completions)
  2) request.json をそのまま送信（汎用チャット補完）
  3) マルチモーダルAPI - 画像認識
  4) 音声文字起こし（分割→文字起こし）
  5) 音声文字起こし + チャット要約
  6) 音声合成API (TTS)
  7) RAG - ドキュメントアップロード
  8) RAG - ドキュメントのステータス確認
  9) RAG - 質問応答 (documents/chat)
  10) MCP - 外部ツール連携デモ (Node.jsサーバー + Pythonクライアント)
  11) シェルを起動 (自由に curl / python / node を実行)
  0) 終了
EOF
  echo
  read -rp "番号を選択してください: " choice
  echo

  case "$choice" in
    1) read -rp "質問文 (空Enterで既定文): " q; python3 01_chat_completion.py "$q" || true; pause ;;
    2) read -rp "request.jsonのパス (空Enterでrequest.json): " f; python3 02_chat_from_json.py ${f:-} || true; pause ;;
    3) read -rp "画像ファイルパス: " f; read -rp "質問文 (空Enterで既定文): " q; python3 03_multimodal_image.py "$f" "$q" || true; pause ;;
    4) read -rp "音声ファイルパス: " f; python3 04_audio_transcription.py --input "$f" || true; pause ;;
    5) read -rp "音声ファイルパス: " f; python3 05_audio_transcription_summary.py --input "$f" || true; pause ;;
    6) read -rp "テキスト (空Enterで既定文): " t; python3 06_audio_speech.py "$t" || true; pause ;;
    7) read -rp "ファイルパス: " f; read -rp "ドキュメント名 (省略可): " n; args=("$f"); [ -n "$n" ] && args+=(--name "$n"); python3 07_rag_upload.py "${args[@]}" || true; pause ;;
    8) read -rp "ドキュメントID: " id; python3 08_rag_status.py "$id" || true; pause ;;
    9) read -rp "質問文: " q; python3 09_rag_query.py "$q" || true; pause ;;
    10) read -rp "質問文 (空Enterで既定文): " q; python3 10_mcp_client.py "$q" || true; pause ;;
    11) echo "シェルを起動します。'exit' で戻ります。"; bash || true ;;
    0) echo "終了します。"; exit 0 ;;
    *) echo "不正な選択です。" ;;
  esac

  menu
}

menu
