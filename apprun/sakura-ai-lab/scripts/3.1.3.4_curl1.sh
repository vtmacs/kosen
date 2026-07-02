curl --location https://api.ai.sakura.ad.jp/v1/chat/completions \
  --header "Accept: application/json" \
  --header "Authorization: Bearer ${AI_ENGINE_TOKEN}" \
  --header "Content-Type: application/json" \
  --data '{
    "model": "gpt-oss-120b",
    "messages": [
      { "role": "system", "content": "こんにちは！" }
    ],
    "temperature": 0.7,
    "max_tokens": 200,
    "stream": false
  }'
