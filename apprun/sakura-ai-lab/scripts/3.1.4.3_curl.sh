curl --request POST \
--url https://api.ai.sakura.ad.jp/v1/audio/transcriptions \
--header 'Accept: application/json' \
--header "Authorization: Bearer ${AI_ENGINE_TOKEN}" \
--header 'Content-Type: multipart/form-data' \
--form 'file=@ai-engine_voice.mp3' \
--form 'model=whisper-large-v3-turbo'
