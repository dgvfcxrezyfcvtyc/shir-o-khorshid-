#!/bin/sh
set -e

export HOST="0.0.0.0"
export PORT="${PORT:-8000}"

if [ -f /code/start.sh ]; then
    exec /code/start.sh
fi

if [ -f /code/main.py ]; then
    exec python /code/main.py
fi

if [ -f /code/app.py ]; then
    exec python /code/app.py
fi

if [ -f /code/pyproject.toml ]; then
    exec uv run uvicorn main:app \
        --host 0.0.0.0 \
        --port "$PORT"
fi

echo "فایل اجرای برنامه پیدا نشد."
exit 1
