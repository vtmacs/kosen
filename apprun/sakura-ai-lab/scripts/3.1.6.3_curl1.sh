curl -X POST "https://api.ai.sakura.ad.jp/v1/chat/completions" \
  -H "Authorization: Bearer ${AI_ENGINE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "preview/Qwen3-VL-30B-A3B-Instruct",
    "messages": [
      {
        "role": "user",
        "content": [
          {
            "type": "text",
            "text": "こんにちは"
          }
        ]
      }
    ],
    "temperature": 0.7,
    "max_tokens": 1000,
    "stream": false
  }' | jq
