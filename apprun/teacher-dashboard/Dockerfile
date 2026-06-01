FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 8080

# メインプロセス1、並列実行スレッド40を固定割り当てして起動
CMD ["gunicorn", "-w", "1", "--threads", "40", "-b", "0.0.0.0:8080", "app:app"]
