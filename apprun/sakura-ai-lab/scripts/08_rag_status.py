#!/usr/bin/env python3
"""
さくらのAI Engine 実践: RAG - ドキュメントのステータス確認

対応する教材: 3.1.3.4_curl_3.txt
  curl -s --location '.../v1/documents/<ドキュメントのID>/' \
       --header "Authorization: Bearer ${AI_ENGINE_TOKEN}" \
  | grep -oE '"id":"[^"]*"|"status":"[^"]*"|"name":"[^"]*"'

アップロード直後はベクトル化処理中のため、statusが完了状態になるまで
数回に分けて確認してください（教材ではgrepでid/status/nameのみ抽出）。

使い方:
  python 08_rag_status.py <ドキュメントID>
"""
import re
import sys

import requests

from common import API_BASE, auth_headers, require_api_key


def main() -> None:
    if len(sys.argv) < 2:
        print("使い方: python 08_rag_status.py <ドキュメントID>", file=sys.stderr)
        sys.exit(1)

    doc_id = sys.argv[1]
    require_api_key()
    url = f"{API_BASE}/documents/{doc_id}/"

    print(f"[GET] {url}\n")
    resp = requests.get(url, headers=auth_headers(json_content=False), timeout=30)
    resp.raise_for_status()

    body = resp.text
    # 教材のgrep -oE '"id":"[^"]*"|"status":"[^"]*"|"name":"[^"]*"' と同じ抽出
    for m in re.finditer(r'"id":"[^"]*"|"status":"[^"]*"|"name":"[^"]*"', body):
        print(m.group(0))


if __name__ == "__main__":
    main()
