curl -X POST "https://api.ai.sakura.ad.jp/v1/chat/completions" \
  -H "Authorization: Bearer ${AI_ENGINE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "preview/Phi-4-multimodal-instruct",
    "messages": [
      {
        "role": "user",
        "content": [
          {
            "type": "text",
            "text": "この画像について説明してください。"
          },
          {
            "type": "image_url",
            "image_url": {
              "url": "https://s3.tky01.sakurastorage.jp/ai-kentei/sakura-office.jpg"
            }
          }
        ]
      }
    ],
    "temperature": 0.7,
    "max_tokens": 2000,
    "stream": false
  }' |jq
