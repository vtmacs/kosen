#!/usr/bin/env python3
"""
さくらのAI Engine 実践: 音声文字起こし（長尺音声の分割対応）

対応する教材: 3.1.4.4_splitmp3.py

音声ファイルを chunk_sec 秒ごとに分割してから、チャンクごとに
/v1/audio/transcriptions へPOSTします（教材の実装に準拠。既定29秒分割）。
出力: transcript.json / transcript.txt（時間範囲付き） / transcript_full.txt（全文結合）

事前準備: ffmpeg が必要です（pydubが内部で利用。Dockerイメージには同梱済み）。

使い方:
  python 04_audio_transcription.py --input sample.mp3
  python 04_audio_transcription.py -i sample.mp3 -s 29 -o chunks
"""
import argparse
import json
import time
from pathlib import Path

import requests
from pydub import AudioSegment

from common import API_BASE, TRANSCRIBE_MODEL, require_api_key

API_URL = f"{API_BASE}/audio/transcriptions"


def mmss(sec: float) -> str:
    m = int(sec) / 60
    s = int(sec) % 60
    return f"{int(m):02d}:{s:02d}"


def split_audio(input_path: Path, outdir: Path, chunk_sec: int) -> list[Path]:
    """音声を chunk_sec 秒ごとに分割して保存。保存したファイルの Path リストを返す。"""
    outdir.mkdir(parents=True, exist_ok=True)
    audio = AudioSegment.from_file(input_path)
    chunk_ms = chunk_sec * 1000
    parts: list[Path] = []
    for i in range(0, len(audio), chunk_ms):
        chunk = audio[i : i + chunk_ms]
        idx = i // chunk_ms
        out_file = outdir / f"output_{idx:03d}.mp3"
        chunk.export(out_file, format="mp3")
        parts.append(out_file)
        start_s = i / 1000
        end_s = min((i + chunk_ms), len(audio)) / 1000
        print(f"[Split] {out_file.name}  ({mmss(start_s)} - {mmss(end_s)})")
    return parts


def transcribe_file(file_path: Path, token: str, retry: int = 3, backoff: float = 2.0) -> dict:
    """1ファイルをAPIへPOSTし、JSONレスポンスを返す。429/5xxはリトライ。"""
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/json",
        # Content-Type は requests が自動設定（multipart 境界含む）
    }
    data = {"model": TRANSCRIBE_MODEL}

    for attempt in range(1, retry + 1):
        with open(file_path, "rb") as f:
            files = {"file": (file_path.name, f, "audio/mpeg")}
            resp = requests.post(API_URL, headers=headers, files=files, data=data, timeout=300)

        if resp.status_code == 200:
            return resp.json()

        if resp.status_code in (429, 500, 502, 503, 504):
            wait = backoff * attempt
            print(f"[Warn] {file_path.name} -> HTTP {resp.status_code}, retry {attempt}/{retry} in {wait:.1f}s ...")
            time.sleep(wait)
            continue

        try:
            err = resp.json()
        except Exception:
            err = resp.text
        raise RuntimeError(f"HTTP {resp.status_code}: {err}")

    raise RuntimeError(f"Failed after {retry} retries: {file_path.name}")


def main() -> None:
    ap = argparse.ArgumentParser(description="Split audio and transcribe each chunk via Sakura AI Engine API")
    ap.add_argument("--input", "-i", default="sample.mp3", help="入力音声ファイル (default: sample.mp3)")
    ap.add_argument("--chunk-sec", "-s", type=int, default=29, help="分割長（秒）(default: 29)")
    ap.add_argument("--outdir", "-o", default="chunks", help="分割ファイルの出力ディレクトリ (default: chunks)")
    ap.add_argument("--sleep", type=float, default=0.0, help="各リクエスト間のスリープ秒（任意。RateLimit対策）")
    args = ap.parse_args()

    token = require_api_key()

    input_path = Path(args.input)
    if not input_path.exists():
        raise SystemExit(f"ERROR: input file not found: {input_path}")

    outdir = Path(args.outdir)
    parts = split_audio(input_path, outdir, args.chunk_sec)
    if not parts:
        raise SystemExit("No chunks produced.")

    full_audio = AudioSegment.from_file(input_path)
    chunk_ms = args.chunk_sec * 1000
    total_chunks = len(parts)

    print(f"\n[Transcribe] {total_chunks} chunks -> {API_URL} (model={TRANSCRIBE_MODEL})\n")

    results = []
    for idx, path in enumerate(parts):
        start_ms = idx * chunk_ms
        end_ms = min((idx + 1) * chunk_ms, len(full_audio))
        start_s = start_ms / 1000
        end_s = end_ms / 1000
        window = f"{mmss(start_s)}-{mmss(end_s)}"
        print(f"[POST] {path.name} ({window})  [{idx + 1}/{total_chunks}]")

        try:
            js = transcribe_file(path, token)
            text = js.get("text", "")
            results.append(
                {
                    "index": idx,
                    "file": path.name,
                    "start_sec": start_s,
                    "end_sec": end_s,
                    "window": window,
                    "model": js.get("model"),
                    "text": text,
                    "raw": js,
                }
            )
            print(f"[OK]  {path.name} -> {len(text)} chars")
        except Exception as e:
            print(f"[ERR] {path.name}: {e}")
            results.append(
                {
                    "index": idx,
                    "file": path.name,
                    "start_sec": start_s,
                    "end_sec": end_s,
                    "window": window,
                    "model": None,
                    "text": "",
                    "error": str(e),
                }
            )

        if args.sleep > 0 and idx < total_chunks - 1:
            time.sleep(args.sleep)

    out_json = Path("transcript.json")
    out_txt = Path("transcript.txt")
    out_full = Path("transcript_full.txt")

    with out_json.open("w", encoding="utf-8") as f:
        json.dump(results, f, ensure_ascii=False, indent=2)

    with out_txt.open("w", encoding="utf-8") as f:
        for r in results:
            line = f"[{r['window']}] {r.get('text', '')}".rstrip()
            f.write(line + "\n")

    with out_full.open("w", encoding="utf-8") as f:
        for r in results:
            txt = (r.get("text") or "").strip()
            if txt:
                f.write(txt + "\n")

    print("\nDone. Saved:")
    print(f" - {out_json.resolve()}")
    print(f" - {out_txt.resolve()}   (時間範囲付き)")
    print(f" - {out_full.resolve()}  (タグ無し・全文結合)")

    print("\n===== transcript_full.txt (全文) =====\n")
    with out_full.open("r", encoding="utf-8") as f:
        print(f.read().strip())
    print("\n===== end of transcript_full.txt =====\n")


if __name__ == "__main__":
    main()
