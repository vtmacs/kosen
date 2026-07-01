#!/usr/bin/env python3
"""
さくらのAI Engine 実践: RAG - APIを使ったRAGの実行（documents/chat）

対応する教材: 3.1.3_ドキュメント連携とRAG_コード有_.docx / 3.1.3.4_curl_4.txt
  curl --request POST --url .../v1/documents/chat/ \
       --header "Authorization: Bearer ${AI_ENGINE_TOKEN}" \
       --header 'Content-Type: application/json' \
       --data '{
         "model": "multilingual-e5-large",
         "chat_model": "gpt-oss-120b",
         "query": "企業として個人情報に注意することは？？",
         "top_k": 3,
         "threshold": 0.6,
         "distance_type": "cosine"
       }'

documents/chat は「ベクトル検索 + LLMによる回答生成」を1コールで行うAPIです。
ベクトル検索結果のみ欲しい場合は --mode query（documents/query/）に切り替えられます
（公式マニュアルの操作ガイド・教材本文の両方に記載されているエンドポイントです）。

distance_type は類似度計算に使う距離メトリクスです（教材より）:
  cosine（既定）: コサイン距離。テキストの類似度測定に適する
  l2          : ユークリッド距離。数値データの類似度測定に適する

使い方:
  python 09_rag_query.py "質問文"
  python 09_rag_query.py "質問文" --mode query
  python 09_rag_query.py "質問文" --distance-type l2
"""
import argparse

import requests

from common import API_BASE, CHAT_MODEL, EMBEDDING_MODEL, auth_headers

DEFAULT_TOP_K = 3
DEFAULT_THRESHOLD = 0.3


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("query", help="質問文")
    ap.add_argument("--mode", choices=["chat", "query"], default="chat")
    ap.add_argument("--top-k", type=int, default=DEFAULT_TOP_K)
    ap.add_argument("--threshold", type=float, default=DEFAULT_THRESHOLD)
    ap.add_argument("--distance-type", choices=["cosine", "l2"], default=None)
    args = ap.parse_args()

    endpoint = "documents/chat/" if args.mode == "chat" else "documents/query/"
    url = f"{API_BASE}/{endpoint}"

    payload = {
        "model": EMBEDDING_MODEL,
        "query": args.query,
        "top_k": args.top_k,
        "threshold": args.threshold,
    }
    if args.distance_type:
        payload["distance_type"] = args.distance_type
    if args.mode == "chat":
        payload["chat_model"] = CHAT_MODEL

    print(f"[POST] {url}")
    print(f"[mode] {args.mode}")
    print(f"[query] {args.query}\n")

    resp = requests.post(url, headers=auth_headers(), json=payload, timeout=60)
    resp.raise_for_status()

    print("--- レスポンス ---")
    print(resp.json())


if __name__ == "__main__":
    main()
