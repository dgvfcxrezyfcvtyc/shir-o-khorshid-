# syntax=docker/dockerfile:1

ARG PYTHON_VERSION=3.12

FROM ghcr.io/astral-sh/uv:python${PYTHON_VERSION}-bookworm-slim AS builder

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=0

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    python3-dev \
    libc6-dev \
    git \
    curl \
    unzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# نصب Bun برای ساخت داشبورد
RUN curl -fsSL <https://bun.sh/install> | bash
import os
from fastapi import FastAPI

app = FastAPI()
COPY start-railway.sh /start-railway.sh
RUN chmod +x /start-railway.sh

ENTRYPOINT ["/start-railway.sh"]

@app.get("/")
def home():
    return {"name": "شیر و خورشید"}

if name == "main":
    import uvicorn

    uvicorn.run(
        app,
        host="0.0.0.0",
        port=int(os.getenv("PORT", "8000")),
    )

ENV PATH="/root/.bun/bin:$PATH"

WORKDIR /build

# آدرس پروژه خودت را جایگزین کن
RUN git clone --depth 1 <https://github.com/YOUR_USERNAME/shir-o-khorshid.git> .

# ساخت فرانت‌اند
RUN if [ -f dashboard/package.json ]; then \
        cd dashboard && \
        bun install --frozen-lockfile && \
        cd .. && \
        if [ -f build_dashboard.sh ]; then bash build_dashboard.sh; fi; \
    fi

# نصب وابستگی‌های پایتون
RUN if [ -f pyproject.toml ]; then \
        uv sync --frozen --no-dev; \
    elif [ -f requirements.txt ]; then \
        uv venv && \
        uv pip install -r requirements.txt; \
    fi


FROM python:${PYTHON_VERSION}-slim-bookworm

WORKDIR /code

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    HOST=0.0.0.0 \
    PORT=8000 \
    PATH="/code/.venv/bin:$PATH"

COPY --from=builder /build /code

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# اسکریپت اجرای برنامه
COPY start-railway.sh /start-railway.sh

RUN chmod +x /start-railway.sh && \
    if [ -f /code/start.sh ]; then chmod +x /code/start.sh; fi

EXPOSE 8000

ENTRYPOINT ["/start-railway.sh"]
