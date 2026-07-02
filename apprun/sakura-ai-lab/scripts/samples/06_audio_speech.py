#!/usr/bin/env python3
"""
さくらのAI Engine 実践: 音声合成API（TTS）

公式マニュアル操作ガイドのサンプルと同一のエンドポイント/パラメータです。
  https://manual.sakura.ad.jp/cloud/ai-engine/03-operation-guide.html
  ※ 同期API・1000文字程度の制限あり。利用には各音声合成モデルの利用規約への
    同意がコントロールパネル側で必要です。

使い方:
  python 06_audio_speech.py "こんにちは、これは音声合成のサンプルです。" [出力ファイル.wav]
"""
import sys
from pathlib import Path

import requests

from common import API_BASE, TTS_MODEL, auth_headers

DEFAULT_TEXT = "こんにちは、これは音声合成のサンプルです。"


def main() -> None:
    text = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_TEXT
    out_path = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("audio-speech-output.wav")

    url = f"{API_BASE}/audio/speech"
    headers = auth_headers()
    headers["Accept"] = "audio/wav"
    payload = {
        "model": TTS_MODEL,
        "input": text,
        "voice": "normal",
        "response_format": "wav",
    }

    print(f"[POST] {url}")
    print(f"[model] {TTS_MODEL}")
    print(f"[text] {text}\n")

    resp = requests.post(url, headers=headers, json=payload, timeout=60)
    resp.raise_for_status()
    out_path.write_bytes(resp.content)

    print(f"音声ファイルを保存しました: {out_path}")


if __name__ == "__main__":
    main()
