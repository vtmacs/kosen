# さくらのAI Engine 実践ラボ環境

「さくらのAI検定：AI実践」教材（3.0〜3.1.7）で扱っているさくらのAI Engineのハンズオンを、
毎回ゼロから環境構築せずに試せるようにしたDockerラボです。

対応範囲:

| # | 内容 | 対応スクリプト | 出典教材 |
|---|------|----------------|------|
| 1 | チャット補完 (chat completions) | `scripts/01_chat_completion.py` | 3.1.1 / 3.1.3.4 |
| 2 | request.jsonをそのまま送信（汎用チャット補完） | `scripts/02_chat_from_json.py` | 3.1.6.4 |
| 3 | マルチモーダルAPI（画像認識・URL/base64両対応） | `scripts/03_multimodal_image.py` | 3.1.6 |
| 4 | 音声文字起こし（分割→文字起こし） | `scripts/04_audio_transcription.py` | 3.1.4.4 |
| 5 | 音声文字起こし + チャット要約 | `scripts/05_audio_transcription_summary.py` | 3.1.4.5 |
| 6 | 音声合成API (TTS) | `scripts/06_audio_speech.py` | 独自実装（教材に該当節なし・要検証） |
| 7 | RAG - ドキュメントアップロード | `scripts/07_rag_upload.py` | 3.1.3.4 |
| 8 | RAG - ドキュメントのステータス確認 | `scripts/08_rag_status.py` | 3.1.3.4 |
| 9 | RAG - 質問応答 (documents/chat・distance_type対応) | `scripts/09_rag_query.py` | 3.1.3 / 3.1.3.4 |
| 10 | MCP - 外部ツール連携（Node.js MCPサーバー） | `scripts/time-server.js` | 3.1.5 |
| 10 | MCP - ヘッドレス代替クライアント（ラボ独自） | `scripts/10_mcp_client.py` | ラボ独自実装 |
| - | Open WebUI（ブラウザチャットUI） | `docker-compose.yml` の `open-webui` サービス | - |

このリポジトリのスクリプトは、提供いただいた教材本文・curl例・Pythonスクリプト
（3_0, 3_1_1, 3_1_2, 3_1_3, 3_1_4, 3_1_5, 3_1_6, 3_1_7）の内容にできるだけ忠実に
なるよう作成しています。「独自実装」と明記した箇所（TTS、MCPのPythonクライアント）は
教材に対応節がない、またはGUI前提の内容をヘッドレス環境向けに置き換えたものです。

### MCPについての重要な注意

教材3.1.5では、**Claude Desktop（GUIアプリ）をMCP Hostとして使い**、
`claude_desktop_config.json` に `time-server.js` を登録することで、対話中に
Claudeが自動的にツールを呼び出す構成をハンズオンとして扱っています。
`scripts/time-server.js` は教材のtime-server.jsと完全に同一の実装です。

このDockerラボはGUIを持たないヘッドレス環境のため、Claude Desktopをそのまま
使うことはできません。手元のPCにClaude Desktopがインストールされている場合は、
`claude_desktop_config.example.json` を参考に設定すれば、教材どおりの体験ができます
（`time-server.js` のパスは、ホスト側にcloneしたこのリポジトリの絶対パスに書き換えてください）。

ヘッドレス環境（このDockerコンテナ内）で動作確認したい場合は、`10_mcp_client.py`
（ラボ独自のPythonクライアント）を使ってください。これは教材の構成そのものではなく、
`time-server.js` を子プロセスとして起動し、さくらのAI EngineのFunction Callingと
組み合わせて同様の挙動を再現する代替手段です。

### 環境変数名について

教材のcurl例・Pythonスクリプトでは `AI_ENGINE_TOKEN` という環境変数名が使われているため、
本リポジトリの `common.py` も `AI_ENGINE_TOKEN` を優先的に読み込みます（`SAKURA_API_KEY` でも
動作します）。`.env.example` を参照してください。

## 0. 事前準備

さくらのクラウド コントロールパネルの「さくらのAI Engine」→「アカウントトークン」から
トークンを発行してください（`<UUID>:<シークレット>` の形式）。

料金プランについて（教材 3.1.7 より）:
- 「基盤モデル無償プラン」「従量課金プラン」の2種類があり、どちらも毎月一定のリクエスト回数まで無料（例：月3,000リクエストまで、といった枠が設けられています。正確な数値はモデル・時期によって変わるため、コントロールパネルの「利用可能なモデル」で確認してください）
- 無償プランは無料枠超過後にレート制御がかかる方式、従量課金プランは超過分が課金される方式です
- **RAGドキュメントの保管料には無料枠がありません**。無償プランでも、ドキュメントを登録した時点からチャンク数（100チャンク単位）に応じた保管料が発生し、削除するまで毎月継続します
- チャット（`/chat/completions`）は「チャット消費のみ」、ベクトル検索のみ（`/documents/query/`）は「埋め込み消費のみ」、RAGチャット（`/documents/chat/`）は「チャット＋埋め込み両方を消費」という違いがあります
- ドキュメント（RAG）の保管には無償枠がありません（利用に応じて課金）

```bash
cp .env.example .env
# .env を開いて SAKURA_API_KEY を書き換える
```

## 1. ローカルでビルド・実行

```bash
docker build -t sakura-ai-engine-lab .
docker run -it --rm --env-file .env -v "$PWD/workspace:/lab/workspace" sakura-ai-engine-lab
```

起動すると、非rootユーザー（`lab`、HOMEは`/lab`）としてtmuxセッションの中でシェル（bash）が
`/lab`直下で開きます。プロンプトは `lab@sakura-ai:home$` のように短く表示されます
（`/lab`にいる時は`home`、`/lab/workspace`にいる時は`workspace`、というように`/lab`からの
相対パスで表示されます）。

`/lab`直下にはハンズオンスクリプトと`workspace/`だけが置かれています。`docker-entrypoint.sh`や
`package.json`などの裏方ファイルは`/opt/lab-infra`に分離してあるので、`ls`しても紛れ込みません。

画像/音声ファイルは `workspace/` に置いてから、`workspace/ファイル名` の形で指定してください
（ホストの `./workspace` がコンテナ内 `/lab/workspace` にマウントされています）。

スクリプトはカレントディレクトリにあるので、そのまま実行できます:

```bash
python3 01_chat_completion.py "こんにちは"
```

番号選択式のCLIメニューも用意していますが、自動起動はしません。使いたい場合はシェルから
手動で起動してください:

```bash
bash /opt/lab-infra/lab-menu.sh
```

コマンド一発で個別スクリプトを叩きたい場合:

```bash
docker run -it --rm --env-file .env sakura-ai-engine-lab \
  python3 01_chat_completion.py "こんにちは"
```

### 接続が切れても画面がリセットされない仕組み（tmux）

ブラウザ経由（ttyd/AppRun）でアクセスした場合、内部では `tmux new-session -A -s lab` を
実行しています。WebSocket接続がタイムアウトや通信断で切れて再接続されても、ttydは
同じtmuxセッションに再アタッチするだけなので、それまでの作業（カレントディレクトリ、
`export`した環境変数、実行中のプロセスなど）はそのまま維持されます。

もしAppRun側のタイムアウト自体を延ばしたい場合は、アプリケーション設定の
`timeout_seconds`（既定60秒）を必要に応じて増やすことも検討してください（tmuxによる
永続化があるので必須ではありませんが、切断・再接続の頻度自体を減らせます）。

MCPハンズオン（10番）は内部で `node time-server.js` を子プロセスとして起動し、
LLMが必要と判断した場合にのみ `get_current_time` を実行します（教材本来はClaude Desktop
から利用する構成です。上記「MCPについての重要な注意」を参照）。

## 2. docker-compose での利用（ラボ + Open WebUI）

```bash
docker compose run --rm lab                # CLIラボを対話利用
docker compose up -d open-webui             # http://localhost:3000 でチャットUI
```

Open WebUI は `OPENAI_API_BASE_URL` / `OPENAI_API_KEY` を さくらのAI Engine に向けることで、
コード不要のチャット体験（Playgroundに近い操作感）を提供します。モデル名はOpen WebUI側の
モデル選択画面で `gpt-oss-120b` 等を指定してください。

## 3. AppRunへのデプロイ

AppRunはHTTPで待受するコンテナが前提のサービスのため、このイメージは `PORT` 環境変数が
設定されている場合、**ttyd** でブラウザ上のターミナル（bashシェル）を公開する構成に
自動的に切り替わります（`docker-entrypoint.sh` 参照）。

手順の概要:

1. さくらのクラウドの「コンテナレジストリ」または Docker Hub / GHCR にイメージをpush
   （AppRunはこれらのレジストリのみ対応。イメージは **linux/amd64**、サイズ上限 **2GiB**）
2. AppRunでアプリケーションを新規作成し、コンポーネントにpush先イメージを指定
3. アプリケーション設定で待受ポートを指定（`PORT` は予約済み環境変数のため自分では設定不可。
   利用不可ポート: `8008, 8012, 8013, 8022, 8443, 9090, 9091`）
4. コンポーネントの環境変数に `SAKURA_API_KEY` 等を設定（1件あたり最大512バイト、最大50個まで）

```bash
docker build -t <レジストリ>/sakura-ai-engine-lab:latest .
docker push <レジストリ>/sakura-ai-engine-lab:latest
```

> Open WebUIは別コンテナのため、AppRunで併用したい場合は本ラボとは別のAppRunアプリ
> （コンポーネント）としてデプロイしてください（AppRunは1アプリ1コンポーネント構成）。

### ネットワークが制限された環境でビルドする場合

`ttyd` のバイナリはGitHub Releasesから取得します。取得できない環境では:

```bash
docker build --build-arg INSTALL_TTYD=false -t sakura-ai-engine-lab .
```

この場合、AppRun（HTTP待受必須）へはそのままデプロイできません。ローカルでの
`docker run -it` 利用や、社内でのイメージ配布に限定してください。

## 4. ディレクトリ構成

### このリポジトリ（ビルドコンテキスト）

`scripts/samples/` に実際に動くハンズオンスクリプト（このリポジトリ用に書き起こしたもの）を、
`scripts/` 直下には教材そのままの生curl例・オリジナルPythonスクリプト・テスト用サンプル素材
（画像/音声/PDF）を置いています。`Dockerfile`がビルド時にこれらを目的別に振り分けます。

```
.
├── Dockerfile
├── docker-entrypoint.sh
├── docker-compose.yml
├── requirements.txt        # Python依存 (requests, python-dotenv, mcp, pydub)
├── package.json            # Node依存 (@modelcontextprotocol/sdk、node_modulesのインストール専用)
├── claude_desktop_config.example.json  # Claude Desktopでtime-server.jsを使う場合の設定例
├── .env.example
├── infra/
│   └── bashrc-lab                     # シェルプロンプト設定 (lab@sakura-ai:home$)
└── scripts/
    ├── samples/                       # ← 実際に動くハンズオンスクリプト本体
    │   ├── common.py                          # 認証情報読み込み等の共通処理
    │   ├── lab-menu.sh                        # CLIメニュー本体（裏方扱い）
    │   ├── start-shell.sh                     # tmuxフォールバック付き起動スクリプト（裏方扱い）
    │   ├── 01_chat_completion.py
    │   ├── 02_chat_from_json.py               # request.jsonをそのまま送信（汎用）
    │   ├── 03_multimodal_image.py             # URL/base64両対応
    │   ├── 04_audio_transcription.py          # 分割→文字起こし（教材準拠）
    │   ├── 05_audio_transcription_summary.py  # 分割→文字起こし→チャット要約（教材準拠）
    │   ├── 06_audio_speech.py
    │   ├── 07_rag_upload.py
    │   ├── 08_rag_status.py
    │   ├── 09_rag_query.py
    │   ├── 10_mcp_client.py                   # ヘッドレス代替クライアント（ラボ独自）
    │   └── time-server.js                     # 教材3.1.5と同一実装（CommonJS）
    │
    ├── 3.1.3.4_curl1〜4.sh                    # 教材の生curl例（チャット補完・RAG）
    ├── 3.1.4.3_curl.sh                        # 教材の生curl例（音声文字起こし）
    ├── 3.1.6.3_create_JSON.sh, curl1〜4.sh    # 教材の生curl例（マルチモーダル）
    ├── splitmp3.py, splitmp3_summary.py       # 教材オリジナルのPythonスクリプト
    ├── time-server.js                         # 教材オリジナル（参考用。動作にはsamples側を使用）
    ├── test.pdf                               # RAGアップロードのテスト用サンプル
    ├── flower.jpg                             # マルチモーダルAPIのテスト用サンプル画像
    ├── ai-engine_voice.mp3                    # 音声文字起こしのテスト用サンプル（短尺）
    └── ai-engine_voice_long.mp3               # 音声文字起こしのテスト用サンプル（長尺・分割確認用）
```

### ビルドされたコンテナ内部（実際にシェルを開いた時に見える構成）

`/lab`にはハンズオンで使うファイルと教材サンプル一式が並び、裏方ファイルは`/opt/lab-infra`に
隔離されています。

```
/lab                              # ← シェルはここで開く（lab@sakura-ai:home$）
├── .bashrc                       # プロンプト設定（隠しファイルなのでlsでは見えない）
├── common.py
├── time-server.js                # 10_mcp_client.pyが実際に使うMCPサーバー本体
├── 01_chat_completion.py
├── ...（02〜10番）
├── workspace/                    # 画像/音声/出力ファイル置き場（ホストとマウント共有可）
└── samples/                      # 教材の生curl例・オリジナルスクリプト・テスト用サンプル素材
    ├── 3.1.3.4_curl1〜4.sh
    ├── 3.1.4.3_curl.sh
    ├── 3.1.6.3_create_JSON.sh, curl1〜4.sh
    ├── splitmp3.py, splitmp3_summary.py
    ├── time-server.reference.js  # 教材オリジナル（参考用。名前を変えて実体と区別）
    ├── test.pdf
    ├── flower.jpg
    ├── ai-engine_voice.mp3
    └── ai-engine_voice_long.mp3

/opt/lab-infra                    # ← 裏方ファイル（普段は見なくてOK）
├── docker-entrypoint.sh
├── start-shell.sh
├── lab-menu.sh
├── package.json
├── node_modules/                 # NODE_PATH経由でtime-server.jsから参照される
└── requirements.txt
```

`samples/`配下のcurl例は`AI_ENGINE_TOKEN`さえ`export`していればそのまま実行できます
（`curl`と`jq`はイメージに同梱済みです）。例:

```bash
export AI_ENGINE_TOKEN="<発行したトークン>"
cd samples
bash 3.1.3.4_curl1.sh        # チャット補完
bash 3.1.4.3_curl.sh         # 音声文字起こし（ai-engine_voice.mp3を使用）
python3 splitmp3.py --input ai-engine_voice_long.mp3   # 長尺音声の分割文字起こし
```

`10_mcp_client.py`が`time-server.js`を子プロセスとして起動する際は同じ`/lab`内にあるため
相対パスのままで問題なく動作します（`samples/time-server.reference.js`は参考用の別ファイルで、
実際の動作には使われません）。Node.jsのモジュール解決は`NODE_PATH=/opt/lab-infra/node_modules`
で通しているため、`time-server.js`が`/lab`にあっても`@modelcontextprotocol/sdk`を正しく読み込めます。

### 音声文字起こしについての重要な注意

音声文字起こしAPIは、さくらのAI Engine側で内部的に最長30分・30MBまでのファイルを
自動分割して処理します。教材のPythonスクリプト（3.1.4.4 / 3.1.4.5）は、この上限を超える
長尺音声にも対応できるよう、**あらかじめクライアント側で29秒単位に分割してから**
チャンクごとに文字起こしAPIへ送信する構成になっています（`04_audio_transcription.py` /
`05_audio_transcription_summary.py` はこれに準拠）。分割にはffmpegが必要で、Dockerイメージには
同梱済みです（`pydub` + `ffmpeg`）。

## 5. 注意事項

- 各スクリプトはAPIキーを `.env` から読み込みます。イメージ自体にキーは埋め込んでいません。
  受講者ごとに自分のアカウントトークンを発行して使ってください。
- RAGのドキュメントアップロードは課金対象です。検証後は `documents/{id}` の削除APIまたは
  コントロールパネルから忘れずに削除してください。
- モデル名（`gpt-oss-120b` など）は提供状況により変わる可能性があります。
  コントロールパネルの「利用可能なモデル」で最新のモデル名を確認し、`.env` を更新してください。
