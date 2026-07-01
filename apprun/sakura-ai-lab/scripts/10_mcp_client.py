#!/usr/bin/env python3
"""
さくらのAI Engine 実践: MCP Serverをヘッドレス環境から利用する簡易クライアント

対応する教材: 3.1.5_MCP構成設計_コード有_.docx

【重要】教材本来のハンズオンでは、GUIアプリの Claude Desktop を MCP Host として
使い、claude_desktop_config.json に time-server.js を登録することで、対話の中で
Claude が自動的にツールを呼び出す構成を扱っています（本リポジトリの
scripts/time-server.js は教材のtime-server.jsと完全に同一の実装です）。

このDockerラボはGUIを持たないヘッドレス環境のため、Claude Desktopをそのまま
使うことができません。そこで本スクリプトは、教材の構成を「体験」するための
ラボ独自の代替クライアントとして、scripts/time-server.js を子プロセスとして
起動し、さくらのAI Engineのchat/completions（Function Calling）と組み合わせて
同様のツール呼び出しの流れを再現します。

事前準備:
  npm install   （プロジェクトルートで一度だけ）

使い方:
  python 10_mcp_client.py "いま何時ですか？"
"""
import asyncio
import json
import sys
from pathlib import Path

import requests
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

from common import API_BASE, CHAT_MODEL, auth_headers

SERVER_SCRIPT = Path(__file__).parent / "time-server.js"
DEFAULT_QUERY = "いま何時ですか？isoフォーマットで教えてください。"


def mcp_tools_to_openai_tools(mcp_tools) -> list[dict]:
    """MCPのツール定義をチャット補完APIのtools(Function Calling)形式に変換する"""
    tools = []
    for t in mcp_tools:
        tools.append(
            {
                "type": "function",
                "function": {
                    "name": t.name,
                    "description": t.description or "",
                    "parameters": t.inputSchema or {"type": "object", "properties": {}},
                },
            }
        )
    return tools


def call_chat_completions(messages: list[dict], tools: list[dict]) -> dict:
    url = f"{API_BASE}/chat/completions"
    payload = {
        "model": CHAT_MODEL,
        "messages": messages,
        "tools": tools,
        "tool_choice": "auto",
        "temperature": 0.2,
        "max_tokens": 500,
    }
    resp = requests.post(url, headers=auth_headers(), json=payload, timeout=60)
    resp.raise_for_status()
    return resp.json()


async def main() -> None:
    query = " ".join(sys.argv[1:]) or DEFAULT_QUERY

    server_params = StdioServerParameters(command="node", args=[str(SERVER_SCRIPT)])

    async with stdio_client(server_params) as (read, write):
        async with ClientSession(read, write) as session:
            await session.initialize()

            mcp_tools_resp = await session.list_tools()
            openai_tools = mcp_tools_to_openai_tools(mcp_tools_resp.tools)
            print(f"[mcp] 利用可能なツール: {[t.name for t in mcp_tools_resp.tools]}\n")

            messages = [{"role": "user", "content": query}]
            print(f"[user] {query}\n")

            first = call_chat_completions(messages, openai_tools)
            choice = first["choices"][0]["message"]

            tool_calls = choice.get("tool_calls") or []
            if not tool_calls:
                print("--- 応答（ツール未使用） ---")
                print(choice.get("content"))
                return

            messages.append(choice)

            for call in tool_calls:
                fn_name = call["function"]["name"]
                try:
                    fn_args = json.loads(call["function"].get("arguments") or "{}")
                except json.JSONDecodeError:
                    fn_args = {}

                print(f"[tool_call] {fn_name}({fn_args})")
                result = await session.call_tool(fn_name, fn_args)
                result_text = "".join(
                    block.text for block in result.content if hasattr(block, "text")
                )
                print(f"[tool_result] {result_text}\n")

                messages.append(
                    {
                        "role": "tool",
                        "tool_call_id": call["id"],
                        "content": result_text,
                    }
                )

            final = call_chat_completions(messages, openai_tools)
            print("--- 応答（ツール利用後） ---")
            print(final["choices"][0]["message"]["content"])


if __name__ == "__main__":
    asyncio.run(main())
