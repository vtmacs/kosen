cat > request.json <<EOF
{
  "model": "preview/Phi-4-multimodal-instruct",
  "messages": [
    {
      "role": "user",
      "content": [
        { "type": "text", "text": "この画像について説明してください。" },
        {
          "type": "image_url",
          "image_url": {
            "url": "data:image/jpeg;base64,$(cat flower.b64)"
          }
        }
      ]
    }
  ],
  "temperature": 0.7,
  "max_tokens": 2000,
  "stream": false
}
EOF
