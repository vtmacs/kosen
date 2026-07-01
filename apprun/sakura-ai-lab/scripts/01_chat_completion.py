#!/usr/bin/env python3
"""
さくらのAI Engine 実践: チャット補完 (chat completions)

対応するブログ記事:
  - さくらのAI Engine 利用開始の手順
  - さくらのAI Engine 実践：Playgroundを使ったチャット

公式マニュアル「利用手順」のサンプルと同じエンドポイント/パラメータを使用します。
  https://manual.sakura.ad.jp/cloud/ai-engine/02-howto.html
"""
import sys

import requests

from common import API_BASE, CHAT_MODEL, auth_headers

DEFAULT_QUERY = "さくらインターネットのAI Engineについて、3行で教えてください。"


def main() -> None:
    query = " ".join(sys.argv[1:]) or DEFAULT_QUERY
    url = f"{API_BASE}/chat/completions"
    payload = {
        "model": CHAT_MODEL,
        "messages": [{"role": "user", "content": query}],
        "temperature": 0.7,
        "max_tokens": 500,
        "stream": False,
    }

    print(f"[POST] {url}")
    print(f"[model] {CHAT_MODEL}")
    print(f"[query] {query}\n")

    resp = requests.post(url, headers=auth_headers(), json=payload, timeout=60)
    resp.raise_for_status()
    data = resp.json()

    print("--- 応答 ---")
    print(data["choices"][0]["message"]["content"])
    print("\n--- usage ---")
    print(data.get("usage"))


if __name__ == "__main__":
    main()
