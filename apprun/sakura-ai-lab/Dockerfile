# ==========================================================================
# さくらのAI検定：AI実践 ラボ環境
# さくらのAI Engine ハンズオン用 Dockerイメージ
#
# - Python 3 (requests / mcp SDK) : チャット補完・RAG・音声・マルチモーダルAPI
# - Node.js (@modelcontextprotocol/sdk) : MCP外部ツール連携ハンズオン
# - ttyd : AppRun（HTTP待受が必須）上でもブラウザ経由でCLIメニューを操作可能にする
#
# AppRunの制約（2026年時点のマニュアルより）:
#   - コンテナは linux/amd64 のみ
#   - イメージサイズ上限 2GiB
#   - PORT 環境変数（予約済み）で待受ポートが渡される
#   - 8008,8012,8013,8022,8443,9090,9091 は利用不可
# ==========================================================================
FROM node:20-bookworm-slim

ARG INSTALL_TTYD=true
ARG TTYD_VERSION=1.7.7

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    LAB_HOME=/lab

# --- OSパッケージ (Python本体 + 音声分割用ffmpeg + 最低限のライブラリ) ---
RUN apt-get update && apt-get install -y --no-install-recommends \
      python3 \
      python3-pip \
      python3-venv \
      curl \
      ca-certificates \
      jq \
      bash \
      ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# --- ttyd (ブラウザ上のターミナル。AppRunのHTTP待受要件を満たすためのラッパー) ---
# ネットワークが制限された環境でビルドする場合は --build-arg INSTALL_TTYD=false を指定してください。
RUN if [ "$INSTALL_TTYD" = "true" ]; then \
      curl -fsSL --retry 3 -o /usr/local/bin/ttyd \
        "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.x86_64" \
      && chmod +x /usr/local/bin/ttyd ; \
    else \
      echo "ttydのインストールをスキップしました（ローカルCLI利用のみ）" ; \
    fi

WORKDIR ${LAB_HOME}

# --- Node.js 依存関係 (MCPハンズオン用) ---
COPY package.json ./
RUN npm install --omit=dev

# --- Python 依存関係 ---
COPY requirements.txt ./
RUN pip3 install --no-cache-dir --break-system-packages -r requirements.txt

# --- ラボ本体 ---
COPY scripts ./scripts
COPY docker-entrypoint.sh ./
COPY .env.example ./
RUN chmod +x ./scripts/lab-menu.sh ./docker-entrypoint.sh ./scripts/time-server.js

# 学生ごとの作業ファイル置き場（アップロード画像・音声・ダウンロード結果など）
RUN mkdir -p ${LAB_HOME}/workspace
WORKDIR ${LAB_HOME}/workspace

EXPOSE 7681
ENTRYPOINT ["/lab/docker-entrypoint.sh"]
