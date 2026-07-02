#!/usr/bin/env python3
"""
さくらのAI Engine 実践: マルチモーダルAPIを使った画像認識

対応する教材: 3.1.6_マルチモーダルAPI実践_コード有_.docx

chat/completions エンドポイントの messages[].content を配列にし、
text と image_url を組み合わせることで画像を含む対話ができます。
画像の指定方法は2通り（教材で両方とも扱われています）:
  1. 公開URLをそのまま指定（--url）
  2. ローカル画像をbase64のdata URIとして埋め込み（既定の動作）

モデルは既定で preview/Phi-4-multimodal-instruct を使用します
（もう1つの選択肢 Qwen3-VL-30B-A3B-Instruct は --model で指定可）。

注意（教材より）: base64画像をcurlに直接埋め込む方式は、画像サイズが大きいと
「Argument list too long」エラーになることがあります（教材環境では約120,000字が
目安）。その場合は 02_chat_from_json.py を使い、request.jsonファイル経由で
送信する方式に切り替えてください。

使い方:
  python 03_multimodal_image.py path/to/image.jpg
  python 03_multimodal_image.py path/to/image.jpg "この画像について説明してください。"
  python 03_multimodal_image.py --url https://s3.tky01.sakurastorage.jp/ai-kentei/sakura-office.jpg
"""
import argparse
import base64
import mimetypes
from pathlib import Path

import requests

from common import API_BASE, MULTIMODAL_MODEL, auth_headers

DEFAULT_PROMPT = "この画像について説明してください。"


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("image", nargs="?", help="ローカル画像ファイル（--url指定時は不要）")
    ap.add_argument("prompt", nargs="?", default=DEFAULT_PROMPT, help="質問文")
    ap.add_argument("--url", default=None, help="ローカルファイルの代わりに画像の公開URLを使う")
    ap.add_argument("--model", default=MULTIMODAL_MODEL, help="使用するマルチモーダルモデル")
    args = ap.parse_args()

    if args.url:
        image_content = {"type": "image_url", "image_url": {"url": args.url}}
        image_desc = args.url
    else:
        if not args.image:
            raise SystemExit("画像ファイルまたは --url を指定してください")
        image_path = Path(args.image)
        if not image_path.exists():
            raise SystemExit(f"画像ファイルが見つかりません: {image_path}")

        mime_type, _ = mimetypes.guess_type(image_path.name)
        mime_type = mime_type or "image/jpeg"
        b64_data = base64.b64encode(image_path.read_bytes()).decode("ascii")
        data_uri = f"data:{mime_type};base64,{b64_data}"
        image_content = {"type": "image_url", "image_url": {"url": data_uri}}
        image_desc = str(image_path)

        if len(b64_data) > 100_000:
            print(
                f"[warn] base64が{len(b64_data):,}文字あります。"
                "curl直埋め込みだと Argument list too long になる可能性があります。"
                "02_chat_from_json.py の利用を検討してください。\n"
            )

    url = f"{API_BASE}/chat/completions"
    payload = {
        "model": args.model,
        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": args.prompt},
                    image_content,
                ],
            }
        ],
        "temperature": 0.7,
        "max_tokens": 2000,
        "stream": False,
    }

    print(f"[POST] {url}")
    print(f"[model] {args.model}")
    print(f"[image] {image_desc}")
    print(f"[prompt] {args.prompt}\n")

    resp = requests.post(url, headers=auth_headers(), json=payload, timeout=120)
    resp.raise_for_status()
    data = resp.json()

    print("--- 応答 ---")
    print(data["choices"][0]["message"]["content"])


if __name__ == "__main__":
    main()
