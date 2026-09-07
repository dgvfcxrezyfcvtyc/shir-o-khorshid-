#!/bin/sh
set -e

# تنظیمات Railway
export HOST="0.0.0.0"
export PORT="${PORT:-8000}"

cd /code

# اگر فایل start.sh وجود داشت، همان را اجرا کن
if [ -x "./start.sh" ]; then
    exec ./start.sh
fi

# اجرای FastAPI با Uvicorn
if [ -f "main.py" ]; then
    exec uvicorn main:app \
        --host "$HOST" \
        --port "$PORT"
fi

# اجرای Flask
if [ -f "app.py" ]; then
    exec gunicorn app:app \
        --bind "$HOST:$PORT"
fi

echo "خطا: فایل اجرای برنامه پیدا نشد."
exit 1
