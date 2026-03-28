FROM python:3.10-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/spotify_history /app/spotify_history

ENTRYPOINT ["python", "-m", "spotify_history"]
CMD ["ingest"]