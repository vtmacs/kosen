#!/usr/bin/env python3
import os
import time
import json
import argparse
from pathlib import Path

import requests
from pydub import AudioSegment

API_URL = "https://api.ai.sakura.ad.jp/v1/audio/transcriptions"
MODEL = "whisper-large-v3-turbo"

CHAT_URL = "https://api.ai.sakura.ad.jp/v1/chat/completions"
CHAT_MODEL_DEFAULT = "gpt-oss-120b"

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
        chunk = audio[i:i + chunk_ms]
        idx = i // chunk_ms
        out_file = outdir / f"output_{idx:03d}.mp3"
        # 互換性重視で再エンコード（ビットレート等が気になる場合は引数で調整）
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
    data = {"model": MODEL}

    for attempt in range(1, retry + 1):
        # 毎回開き直してクリーンに送る
        with open(file_path, "rb") as f:
            files = {"file": (file_path.name, f, "audio/mpeg")}
            resp = requests.post(API_URL, headers=headers, files=files, data=data, timeout=300)

        if resp.status_code == 200:
            return resp.json()

        if resp.status_code in (429, 500, 502, 503, 504):
            # リトライ対象
            wait = backoff * attempt
            print(f"[Warn] {file_path.name} -> HTTP {resp.status_code}, retry {attempt}/{retry} in {wait:.1f}s ...")
            time.sleep(wait)
            continue

        # 4xxなどはエラー内容を表示して即終了
        try:
            err = resp.json()
        except Exception:
            err = resp.text
        raise RuntimeError(f"HTTP {resp.status_code}: {err}")

    raise RuntimeError(f"Failed after {retry} retries: {file_path.name}")

# ===== ここからチャット要約の追加関数 =====

def chat_complete(messages: list[dict], token: str, model: str, temperature: float, max_tokens: int,
                  retry: int = 3, backoff: float = 2.0) -> str:
    """Chat Completions を叩いてアシスタントの content を返す。429/5xx はリトライ。"""
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/json",
        "Content-Type": "application/json",
    }
    payload = {
        "model": model,
        "messages": messages,
        "temperature": temperature,
        "max_tokens": max_tokens,
        "stream": False,
    }

    for attempt in range(1, retry + 1):
        resp = requests.post(CHAT_URL, headers=headers, json=payload, timeout=300)
        if resp.status_code == 200:
            js = resp.json()
            # 期待する構造: {"choices":[{"message":{"role":"assistant","content":"..."}}], ...}
            try:
                return js["choices"][0]["message"]["content"]
            except Exception:
                raise RuntimeError(f"Unexpected response schema: {json.dumps(js, ensure_ascii=False)[:500]}")
        if resp.status_code in (429, 500, 502, 503, 504):
            wait = backoff * attempt
            print(f"[Warn] Chat HTTP {resp.status_code}, retry {attempt}/{retry} in {wait:.1f}s ...")
            time.sleep(wait)
            continue
        try:
            err = resp.json()
        except Exception:
            err = resp.text
        raise RuntimeError(f"Chat HTTP {resp.status_code}: {err}")

    raise RuntimeError(f"Chat failed after {retry} retries.")

def chunk_strings(s: str, chunk_chars: int) -> list[str]:
    """長文を概ね chunk_chars 文字で分割（語の途中でもよい簡易版）。"""
    if chunk_chars <= 0 or len(s) <= chunk_chars:
        return [s]
    return [s[i:i+chunk_chars] for i in range(0, len(s), chunk_chars)]

def summarize_text_via_chat(
    text: str,
    token: str,
    model: str = CHAT_MODEL_DEFAULT,
    per_chunk_chars: int = 6000,
    temperature: float = 0.3,
    max_tokens: int = 800,
    system_prompt: str | None = None,
) -> str:
    """
    長い transcript を安全に要約するための map-reduce 要約。
    1) 文章をチャンクに分けて各チャンクを要約
    2) その要約群をさらに要約
    """
    if not text.strip():
        return ""

    system_prompt = system_prompt or (
        "あなたは会議録の要約アシスタントです。"
        "重要な決定事項、論点、アクションアイテム、日付/時間参照を日本語の箇条書きで簡潔に整理してください。"
        "固有名詞・数値・時刻は可能な限り正確に残してください。"
    )

    # 1) チャンクごとの要約
    chunks = chunk_strings(text, per_chunk_chars)
    partial_summaries: list[str] = []

    for i, ch in enumerate(chunks, 1):
        print(f"[Chat] Summarizing chunk {i}/{len(chunks)} (len={len(ch)})")
        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": "以下を日本語で要約してください。できるだけ箇条書きで:\n\n" + ch},
        ]
        summary = chat_complete(messages, token, model, temperature, max_tokens)
        partial_summaries.append(f"### 部分要約 {i}\n{summary}")

    # 2) 部分要約をさらに集約
    if len(partial_summaries) == 1:
        return partial_summaries[0]

    merged = "\n\n".join(partial_summaries)
    final_messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": "以下の部分要約を踏まえて、重複を除き、最終要約を日本語で箇条書き中心に簡潔にまとめてください。\n\n" + merged},
    ]
    final_summary = chat_complete(final_messages, token, model, temperature, max_tokens)
    return final_summary

# ===== ここまで追加関数 =====

def main():
    ap = argparse.ArgumentParser(description="Split MP3 by N seconds, transcribe via Sakura AI API, then summarize by Chat Completions")
    ap.add_argument("--input", "-i", default="sample.mp3", help="入力MP3パス (default: sample.mp3)")
    ap.add_argument("--chunk-sec", "-s", type=int, default=29, help="分割長（秒）(default: 29)")
    ap.add_argument("--outdir", "-o", default="chunks", help="分割ファイルの出力ディレクトリ (default: chunks)")
    ap.add_argument("--token", "-t", default=os.getenv("AI_ENGINE_TOKEN"), help="APIトークン（環境変数 AI_ENGINE_TOKENが無ければ指定）")
    ap.add_argument("--sleep", type=float, default=0.0, help="各リクエスト間のスリープ秒（任意。RateLimit対策）")

    # ▼▼ Chat 要約用 追加オプション ▼▼
    ap.add_argument("--chat-model", default=CHAT_MODEL_DEFAULT, help=f"チャット要約に使うモデル (default: {CHAT_MODEL_DEFAULT})")
    ap.add_argument("--summary-chars", type=int, default=6000, help="要約時のチャンク文字数 (default: 6000)")
    ap.add_argument("--summary-max-tokens", type=int, default=800, help="要約出力の max_tokens (default: 800)")
    ap.add_argument("--summary-temp", type=float, default=0.3, help="要約時の temperature (default: 0.3)")
    ap.add_argument("--summary-prompt", default=None, help="要約用 system プロンプト（未指定なら既定の日本語要約プロンプト）")
    ap.add_argument("--no-summarize", action="store_true", help="transcript_full.txt のチャット要約を実行しない")
    # ▲▲ 追加オプション ▲▲

    args = ap.parse_args()

    if not args.token:
        raise SystemExit("ERROR: API token not provided. Set AI_ENGINE_TOKENor use --token")

    input_path = Path(args.input)
    if not input_path.exists():
        raise SystemExit(f"ERROR: input file not found: {input_path}")

    outdir = Path(args.outdir)
    # 分割
    parts = split_audio(input_path, outdir, args.chunk_sec)
    if not parts:
        raise SystemExit("No chunks produced.")

    # 元音声（タイムスタンプ用）
    full_audio = AudioSegment.from_file(input_path)
    chunk_ms = args.chunk_sec * 1000
    total_chunks = len(parts)

    print(f"\n[Transcribe] {total_chunks} chunks -> {API_URL} (model={MODEL})\n")

    results = []
    for idx, path in enumerate(parts):
        start_ms = idx * chunk_ms
        end_ms = min((idx + 1) * chunk_ms, len(full_audio))
        start_s = start_ms / 1000
        end_s = end_ms / 1000
        window = f"{mmss(start_s)}-{mmss(end_s)}"
        print(f"[POST] {path.name} ({window})  [{idx+1}/{total_chunks}]")

        try:
            js = transcribe_file(path, args.token)
            text = js.get("text", "")
            results.append({
                "index": idx,
                "file": path.name,
                "start_sec": start_s,
                "end_sec": end_s,
                "window": window,
                "model": js.get("model"),
                "text": text,
                "raw": js,
            })
            print(f"[OK]  {path.name} -> {len(text)} chars")
        except Exception as e:
            print(f"[ERR] {path.name}: {e}")
            results.append({
                "index": idx,
                "file": path.name,
                "start_sec": start_s,
                "end_sec": end_s,
                "window": window,
                "model": None,
                "text": "",
                "error": str(e),
            })

        if args.sleep > 0 and idx < total_chunks - 1:
            time.sleep(args.sleep)

    # 出力（JSON、タイムタグ付き、全文連結）
    out_json = Path("transcript.json")
    out_txt = Path("transcript.txt")           # [MM:SS-MM:SS] テキスト
    out_full = Path("transcript_full.txt")     # タグ無しの全文結合

    with out_json.open("w", encoding="utf-8") as f:
        json.dump(results, f, ensure_ascii=False, indent=2)

    with out_txt.open("w", encoding="utf-8") as f:
        for r in results:
            line = f"[{r['window']}] {r.get('text','')}".rstrip()
            f.write(line + "\n")

    with out_full.open("w", encoding="utf-8") as f:
        for r in results:
            txt = (r.get("text") or "").strip()
            if txt:
                f.write(txt + "\n")

    print("\n Done. Saved:")
    print(f" - {out_json.resolve()}")
    print(f" - {out_txt.resolve()}   (時間範囲付き)")
    print(f" - {out_full.resolve()}  (タグ無し・全文結合)")
    print("")

    # ★ transcript_full.txt を標準出力にも表示
    print("\n===== transcript_full.txt (全文) =====\n")
    with out_full.open("r", encoding="utf-8") as f:
        full_text = f.read().strip()
        print(full_text)
    print("\n===== end of transcript_full.txt =====\n")

    # ===== 追加: transcript_full.txt を Chat Completions で要約 =====
    if not args.no_summarize:
        print("[Chat] 要約を開始します …")
        try:
            final_summary = summarize_text_via_chat(
                text=full_text,
                token=args.token,
                model=args.chat_model,
                per_chunk_chars=args.summary_chars,
                temperature=args.summary_temp,
                max_tokens=args.summary_max_tokens,
                system_prompt=args.summary_prompt,
            )
            out_summary = Path("transcript_summary.md")
            out_summary.write_text(final_summary.strip() + "\n", encoding="utf-8")
            print("\n 要約を保存しました:")
            print(f" - {out_summary.resolve()}\n")
            print("===== transcript_summary.md (要約) =====\n")
            print(final_summary.strip())
            print("\n===== end of transcript_summary.md =====\n")
        except Exception as e:
            print(f"[ERR] 要約に失敗しました: {e}")

if __name__ == "__main__":
    main()
