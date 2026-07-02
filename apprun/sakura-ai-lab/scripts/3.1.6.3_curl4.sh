curl -X POST "https://api.ai.sakura.ad.jp/v1/chat/completions" \
-H "Authorization: Bearer ${AI_ENGINE_TOKEN}" \
-H "Content-Type: application/json" \
--data-binary @request.json | jq
