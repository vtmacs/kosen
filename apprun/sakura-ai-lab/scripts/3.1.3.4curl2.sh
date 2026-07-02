curl --request POST \
  --url https://api.ai.sakura.ad.jp/v1/documents/upload/ \
  --header 'Accept: application/json' \
  --header "Authorization: Bearer ${AI_ENGINE_TOKEN}" \
  --header 'Content-Type: multipart/form-data' \
  --form "file=@test.pdf"
