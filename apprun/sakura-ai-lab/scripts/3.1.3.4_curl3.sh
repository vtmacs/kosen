# 必ずドキュメントのIDを調べてから実行してください。
curl -s --location 'https://api.ai.sakura.ad.jp/v1/documents/<ドキュメントのID>/' \
  --header "Authorization: Bearer ${AI_ENGINE_TOKEN}" \
| grep -oE '"id":"[^"]*"|"status":"[^"]*"|"name":"[^"]*"'
