FROM node:20-bookworm-slim AS web-builder

WORKDIR /build/web

COPY web/package.json web/package-lock.json ./
RUN npm config set registry https://registry.npmmirror.com && npm ci

COPY web/ ./
RUN npm run build


FROM python:3.11-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libc6-dev \
    libffi-dev \
    python3-dev \
    zlib1g-dev \
    libjpeg-dev \
    libpng-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt ./
RUN pip config set global.index-url https://mirrors.aliyun.com/pypi/simple/ \
    && pip install --no-cache-dir -r requirements.txt \
    && rm -rf /root/.cache/pip \
    && find /usr/local/lib/python3.11 -name "*.pyc" -delete \
    && find /usr/local/lib/python3.11 -name "__pycache__" -delete \
    && apt-get purge -y gcc libc6-dev libffi-dev python3-dev zlib1g-dev libjpeg-dev libpng-dev \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

COPY . ./
COPY --from=web-builder /build/web/static /app/web/static

RUN mkdir -p /app/data /app/log /app/strm /app/plugins

EXPOSE 5211

CMD ["python", "main.py"]
