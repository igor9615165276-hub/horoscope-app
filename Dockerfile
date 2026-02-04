FROM python:3.11-slim

WORKDIR /app

# Ставим зависимости бекенда
COPY backend/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

# Копируем код бекенда
COPY backend /app/backend

# Копируем ключ Firebase Admin SDK внутрь контейнера
COPY serviceAccountKey.json /app/serviceAccountKey.json
ENV FCM_CREDENTIALS_FILE=/app/serviceAccountKey.json

ENV PYTHONUNBUFFERED=1

# Команда для основного сервиса (FastAPI)
CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8000"]
