#!/usr/bin/env node

const { Server } = require("@modelcontextprotocol/sdk/server/index.js");
const { StdioServerTransport } = require("@modelcontextprotocol/sdk/server/stdio.js");
const {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} = require("@modelcontextprotocol/sdk/types.js");

// MCPサーバーの作成
const server = new Server(
  {
    name: "time-server",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// ツール一覧のハンドラー
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "get_current_time",
        description: "現在の時刻を取得します",
        inputSchema: {
          type: "object",
          properties: {
            format: {
              type: "string",
              description: "時刻のフォーマット (iso, locale, unix のいずれか)",
              enum: ["iso", "locale", "unix"],
            },
          },
        },
      },
    ],
  };
});

// ツール呼び出しのハンドラー
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  if (request.params.name === "get_current_time") {
    const format = request.params.arguments?.format || "iso";
    const now = new Date();
    
    let timeString;
    switch (format) {
      case "iso":
        timeString = now.toISOString();
        break;
      case "locale":
        timeString = now.toLocaleString("ja-JP", { 
          timeZone: "Asia/Tokyo",
          year: 'numeric',
          month: '2-digit',
          day: '2-digit',
          hour: '2-digit',
          minute: '2-digit',
          second: '2-digit'
        });
        break;
      case "unix":
        timeString = Math.floor(now.getTime() / 1000).toString();
        break;
      default:
        timeString = now.toISOString();
    }

    return {
      content: [
        {
          type: "text",
          text: `現在の時刻: ${timeString}`,
        },
      ],
    };
  }

  throw new Error(`Unknown tool: ${request.params.name}`);
});

// サーバーの起動
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("Time MCP Server running on stdio");
}

main().catch((error) => {
  console.error("Server error:", error);
  process.exit(1);
});
