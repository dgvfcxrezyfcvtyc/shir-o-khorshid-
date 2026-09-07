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
    && rm -rf /var/lib/apt/lists/*

# نصب Bun برای ساخت فرانت‌اند پنل
RUN curl -fsSL https://github.com/dgvfcxrezyfcvtyc/shir-o-khorshid- | bash

ENV PATH="/root/.bun/bin:$PATH"

WORKDIR /build

# آدرس ریپازیتوری پنل شیر و خورشید را اینجا قرار دهید
ARG PANEL_REPO=https://github.com/USERNAME/shir-o-khorshid-panel.git
RUN git clone --depth 1 ${PANEL_REPO} .

# ساخت فرانت‌اند در صورت وجود داشبورد
RUN if [ -d dashboard ]; then \
        cd dashboard && \
        bun install --frozen-lockfile && \
        cd .. && \
        if [ -f build_dashboard.sh ]; then bash build_dashboard.sh; fi; \
    fi

# نصب وابستگی‌های پایتون
RUN if [ -f pyproject.toml ]; then uv sync --frozen --no-dev; fi

# ایمیج نهایی
FROM python:${PYTHON_VERSION}-slim-bookworm

WORKDIR /code

COPY --from=builder /build /code

ENV PATH="/code/.venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PORT=8000 \
    HOST=0.0.0.0

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY start-railway.sh /start-railway.sh

RUN chmod +x /start-railway.sh \
    && if [ -f /code/start.sh ]; then chmod +x /code/start.sh; fi

EXPOSE 8000

ENTRYPOINT ["/start-railway.sh]
# syntax=docker/dockerfile:1

FROM oven/bun:1

WORKDIR /app

COPY package.json bun.lockb* ./

RUN bun install

COPY . .

EXPOSE 3000

CMD ["bun", "run", "start"]
