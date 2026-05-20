FROM python:3.10-slim

WORKDIR /app

# Flaskと、通信用のrequests、本番サーバー用のgunicornをインストール
RUN pip install --no-cache-dir Flask requests gunicorn

COPY app.py .

EXPOSE 8080

# gunicornを使って安全に起動（ポート8080で待受）
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "1", "--threads", "4", "app:app"]