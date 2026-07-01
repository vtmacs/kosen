#!/usr/bin/env python3
"""
さくらのAI Engine 実践: request.json をそのまま投げる汎用チャット補完クライアント

対応する教材: 3.1.6.4_curl.txt
  curl -X POST ".../chat/completions" -H "Authorization: Bearer ${AI_ENGINE_TOKEN}" \
       -H "Content-Type: application/json" --data-binary @request.json | jq

Function Calling（tools）や response_format など、curlで直接JSONを組み立てて
試したいケース向けのラッパーです。request.json はカレントディレクトリに
自分で用意してください（例はworkspace/request.example.jsonを参照）。

使い方:
  python 02_chat_from_json.py request.json
  python 02_chat_from_json.py             # request.json を既定で探す
"""
import json
import sys
from pathlib import Path

import requests

from common import API_BASE, auth_headers

DEFAULT_REQUEST = {
    "model": "gpt-oss-120b",
    "messages": [{"role": "user", "content": "こんにちは！自己紹介してください。"}],
    "temperature": 0.7,
    "max_tokens": 200,
    "stream": False,
}


def main() -> None:
    req_path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("request.json")

    if req_path.exists():
        payload = json.loads(req_path.read_text(encoding="utf-8"))
        print(f"[file] {req_path} を読み込みました")
    else:
        payload = DEFAULT_REQUEST
        print(f"[info] {req_path} が見つからないため、既定のリクエストを使用します")
        example = Path("request.example.json")
        if not example.exists():
            example.write_text(json.dumps(DEFAULT_REQUEST, ensure_ascii=False, indent=2), encoding="utf-8")
            print(f"[info] サンプルとして {example.resolve()} を作成しました。編集して --input で使えます。")

    url = f"{API_BASE}/chat/completions"
    print(f"[POST] {url}\n")

    resp = requests.post(url, headers=auth_headers(), json=payload, timeout=120)
    resp.raise_for_status()

    print(json.dumps(resp.json(), ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
