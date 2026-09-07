#!/usr/bin/env bash
set -e

cd /code

export HOST="${HOST:-0.0.0.0}"
export PORT="${PORT:-8000}"

if [ -f ./start.sh ]; then
    exec ./start.sh
elif [ -f ./main.py ]; then
    exec python main.py --host "$HOST" --port "$PORT"
elif [ -f ./app.py ]; then
    exec python app.py
else
    exec python -m uvicorn main:app \
        --host "$HOST" \
        --port "$PORT"
fi
