"""
さくらのAI Engine 実践ラボ - 共通ヘルパー

各スクリプトはここから API トークンやベースURLを取得します。
参考: さくらのクラウド マニュアル「さくらのAI Engine」操作ガイド
      https://manual.sakura.ad.jp/cloud/ai-engine/03-operation-guide.html
"""
import os
import sys

from dotenv import load_dotenv

load_dotenv()

API_BASE = os.environ.get("SAKURA_API_BASE", "https://api.ai.sakura.ad.jp/v1")
# 教材のcurl例では環境変数名が AI_ENGINE_TOKEN のため、そちらも優先的に見にいく
API_KEY = os.environ.get("AI_ENGINE_TOKEN") or os.environ.get("SAKURA_API_KEY", "")

CHAT_MODEL = os.environ.get("SAKURA_CHAT_MODEL", "gpt-oss-120b")
MULTIMODAL_MODEL = os.environ.get("SAKURA_MULTIMODAL_MODEL", "preview/Phi-4-multimodal-instruct")
EMBEDDING_MODEL = os.environ.get("SAKURA_EMBEDDING_MODEL", "multilingual-e5-large")
TRANSCRIBE_MODEL = os.environ.get("SAKURA_TRANSCRIBE_MODEL", "whisper-large-v3-turbo")
TTS_MODEL = os.environ.get("SAKURA_TTS_MODEL", "zundamon")


def require_api_key() -> str:
    if not API_KEY or API_KEY.startswith("<"):
        print(
            "エラー: APIトークンが設定されていません。\n"
            "  .env ファイル（.env.example をコピー）に、コントロールパネルで発行した\n"
            "  アカウントトークンを AI_ENGINE_TOKEN（または SAKURA_API_KEY）として\n"
            "  <UUID>:<シークレット> の形式で設定してください。",
            file=sys.stderr,
        )
        sys.exit(1)
    return API_KEY


def auth_headers(json_content: bool = True) -> dict:
    headers = {
        "Accept": "application/json",
        "Authorization": f"Bearer {require_api_key()}",
    }
    if json_content:
        headers["Content-Type"] = "application/json"
    return headers
