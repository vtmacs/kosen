#!/usr/bin/env python3
"""
さくらのAI Engine 実践: RAG - ドキュメントのアップロード

対応する教材: 3.1.3.4_curl_2.txt
  curl --request POST --url .../v1/documents/upload/ \
       --header "Authorization: Bearer ${AI_ENGINE_TOKEN}" \
       --header 'Content-Type: multipart/form-data' \
       --form "file=@test.pdf"

最低限ファイルだけ指定すればアップロードできます。name/tags/model は
任意パラメータとして追加できます（省略時はサービス側の既定値が使われます）。

! 注意（教材より）: RAGドキュメントを登録すると、削除するまでチャンク数に応じた
保管料が毎月継続的に発生します（無償プランでも課金対象）。検証用ドキュメントは
使い終わったら忘れずに削除してください。

使い方:
  python 07_rag_upload.py path/to/document.pdf
  python 07_rag_upload.py path/to/document.pdf --name "社内規程" --tags 規程 人事
"""
import argparse
from pathlib import Path

import requests

from common import API_BASE, EMBEDDING_MODEL, auth_headers, require_api_key


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("file", help="アップロードするファイル")
    ap.add_argument("--name", default=None, help="ドキュメント名（省略時はファイル名）")
    ap.add_argument("--tags", nargs="*", default=[], help="タグ（スペース区切りで複数可）")
    ap.add_argument("--model", default=None, help=f"埋め込みモデル（省略時は既定: {EMBEDDING_MODEL}）")
    args = ap.parse_args()

    file_path = Path(args.file)
    if not file_path.exists():
        raise SystemExit(f"ファイルが見つかりません: {file_path}")

    require_api_key()
    url = f"{API_BASE}/documents/upload/"
    headers = auth_headers(json_content=False)

    print(f"[POST] {url}")
    print(f"[file] {file_path}\n")

    with file_path.open("rb") as f:
        files = {"file": (file_path.name, f)}
        data = []
        if args.name:
            data.append(("name", args.name))
        if args.model:
            data.append(("model", args.model))
        for tag in args.tags:
            data.append(("tags", tag))
        resp = requests.post(url, headers=headers, files=files, data=data or None, timeout=120)

    resp.raise_for_status()
    print("--- レスポンス ---")
    result = resp.json()
    print(result)
    doc_id = result.get("id")
    if doc_id:
        print(f"\nドキュメントID: {doc_id}")
        print(f"ステータス確認: python 08_rag_status.py {doc_id}")


if __name__ == "__main__":
    main()
