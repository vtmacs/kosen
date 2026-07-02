# ==========================================================================
# さくらのAI検定：AI実践 ラボ環境
# さくらのAI Engine ハンズオン用 Dockerイメージ
#
# - Python 3 (requests / mcp SDK) : チャット補完・RAG・音声・マルチモーダルAPI
# - Node.js (@modelcontextprotocol/sdk) : MCP外部ツール連携ハンズオン
# - ttyd + tmux : AppRun（HTTP待受が必須）上でもブラウザ経由でシェルを操作可能にする。
#   tmuxで永続セッションを維持するため、WebSocketが再接続されても画面がリセットされない。
# - 実行ユーザーは非root（lab）、HOMEは /lab
#
# ディレクトリ構成:
#   /lab           = ユーザーのホーム。教材の生curl例・オリジナルスクリプト・テスト用サンプル素材を直置き
#   /lab/samples   = 実際に動くハンズオンスクリプト一式（01〜10番 等）とworkspace
#   /opt/lab-infra = entrypoint / package.json / node_modules など裏方ファイル
#                    （ユーザーが/labを見た時に紛れ込まないようにするため分離）
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
    PYTHONIOENCODING=utf-8 \
    LAB_HOME=/lab \
    HOME=/lab \
    INFRA_HOME=/opt/lab-infra

# --- OSパッケージ (Python本体 + 音声分割用ffmpeg + tmux + 日本語ロケール + エディタ + 最低限のライブラリ) ---
RUN apt-get update && apt-get install -y --no-install-recommends \
      python3 \
      python3-pip \
      python3-venv \
      curl \
      ca-certificates \
      jq \
      bash \
      ffmpeg \
      tmux \
      locales \
      vim \
      nano \
    && sed -i 's/^# *ja_JP.UTF-8 UTF-8/ja_JP.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen ja_JP.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=ja_JP.UTF-8 \
    LANGUAGE=ja_JP:ja \
    LC_ALL=ja_JP.UTF-8

# --- ttyd (ブラウザ上のターミナル。AppRunのHTTP待受要件を満たすためのラッパー) ---
# ネットワークが制限された環境でビルドする場合は --build-arg INSTALL_TTYD=false を指定してください。
RUN if [ "$INSTALL_TTYD" = "true" ]; then \
      curl -fsSL --retry 3 -o /usr/local/bin/ttyd \
        "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.x86_64" \
      && chmod +x /usr/local/bin/ttyd ; \
    else \
      echo "ttydのインストールをスキップしました（ローカルCLI利用のみ）" ; \
    fi

# ==========================================================================
# インフラ系ファイル一式（ /opt/lab-infra ）
# ==========================================================================
WORKDIR ${INFRA_HOME}

# --- Node.js 依存関係 (MCPハンズオン用) ---
COPY package.json ./
RUN npm install --omit=dev
# time-server.js（/lab側）から require() で見つけられるよう NODE_PATH を通す
ENV NODE_PATH=${INFRA_HOME}/node_modules

# --- Python 依存関係 ---
COPY requirements.txt ./
RUN pip3 install --no-cache-dir --break-system-packages -r requirements.txt

# --- entrypoint / 補助スクリプト ---
COPY docker-entrypoint.sh ./
COPY scripts/samples/start-shell.sh ./
COPY scripts/samples/lab-menu.sh ./
COPY infra/bashrc-lab ./
RUN chmod +x ./docker-entrypoint.sh ./start-shell.sh ./lab-menu.sh

# ==========================================================================
# ユーザー向けファイル一式（ /lab ＝ ホーム。教材の生curl例・サンプル素材を直置き ）
# ==========================================================================
WORKDIR ${LAB_HOME}

# --- 教材の生curl例・オリジナルPythonスクリプト・テスト用サンプル素材（起動直後に見える場所） ---
COPY scripts/3.1.3.4_curl1.sh        ./
COPY scripts/3.1.3.4_curl2.sh        ./
COPY scripts/3.1.3.4_curl3.sh        ./
COPY scripts/3.1.3.4_curl4.sh        ./
COPY scripts/3.1.4.3_curl.sh         ./
COPY scripts/3.1.6.3_create_JSON.sh  ./
COPY scripts/3.1.6.3_curl1.sh        ./
COPY scripts/3.1.6.3_curl2.sh        ./
COPY scripts/3.1.6.3_curl3.sh        ./
COPY scripts/3.1.6.3_curl4.sh        ./
COPY scripts/splitmp3.py             ./
COPY scripts/splitmp3+summary.py     ./
COPY scripts/time-server.js          ./
COPY scripts/test.pdf                ./
COPY scripts/flower.jpg              ./
COPY scripts/ai-engine_voice.mp3     ./
COPY scripts/ai-engine_voice_long.mp3 ./
COPY scripts/claude_desktop_config.example.json ./

# --- 実際に動くハンズオンスクリプト一式（ /lab/samples ） ---
RUN mkdir -p ${LAB_HOME}/samples
COPY scripts/samples/common.py                          ${LAB_HOME}/samples/
COPY scripts/samples/time-server.js                     ${LAB_HOME}/samples/
COPY scripts/samples/01_chat_completion.py               ${LAB_HOME}/samples/
COPY scripts/samples/02_chat_from_json.py                ${LAB_HOME}/samples/
COPY scripts/samples/03_multimodal_image.py               ${LAB_HOME}/samples/
COPY scripts/samples/04_audio_transcription.py            ${LAB_HOME}/samples/
COPY scripts/samples/05_audio_transcription_summary.py    ${LAB_HOME}/samples/
COPY scripts/samples/06_audio_speech.py                   ${LAB_HOME}/samples/
COPY scripts/samples/07_rag_upload.py                     ${LAB_HOME}/samples/
COPY scripts/samples/08_rag_status.py                     ${LAB_HOME}/samples/
COPY scripts/samples/09_rag_query.py                      ${LAB_HOME}/samples/
COPY scripts/samples/10_mcp_client.py                     ${LAB_HOME}/samples/

RUN mkdir -p ${LAB_HOME}/samples/workspace \
    && chmod +x ${LAB_HOME}/*.sh ${LAB_HOME}/time-server.js ${LAB_HOME}/samples/time-server.js \
    && cp ${INFRA_HOME}/bashrc-lab ${LAB_HOME}/.bashrc

# --- 非rootユーザーを作成（HOMEを/labに設定）し、必要な場所の所有者・権限を調整 ---
RUN useradd --no-create-home --home-dir ${LAB_HOME} --shell /bin/bash lab \
    && chown -R lab:lab ${LAB_HOME} \
    && chmod -R a+rX ${INFRA_HOME}
USER lab

WORKDIR ${LAB_HOME}

EXPOSE 7681
ENTRYPOINT ["/opt/lab-infra/docker-entrypoint.sh"]
