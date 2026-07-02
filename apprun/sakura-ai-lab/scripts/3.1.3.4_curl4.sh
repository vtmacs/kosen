curl --request POST \
  --url https://api.ai.sakura.ad.jp/v1/documents/chat/ \
  --header 'Accept: application/json' \
  --header "Authorization: Bearer ${AI_ENGINE_TOKEN}" \
  --header 'Content-Type: application/json' \
  --data '{
    "model": "multilingual-e5-large",
    "chat_model": "gpt-oss-120b",
    "query": "企業として個人情報に注意することは？？",
    "top_k": 3,
    "threshold": 0.6,
    "distance_type": "cosine"
  }'
