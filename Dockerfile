# ===== Runtime base (slim but with deps Streamlit/SSL need) =====
FROM python:3.11-slim-bookworm

# ---- Basic env & folders
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PORT=5002 \
    APP_HOME=/app
WORKDIR ${APP_HOME}

# ---- OS packages required for proper Streamlit rendering + HTTPS
# fonts: fix ugly tables/text; libnss3/ca-certs: TLS; xlibs/asound: UI deps some libs expect
# build-essential: only if a few wheels need compiling; safe to keep for reliability
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl \
    fonts-liberation fonts-dejavu-core \
    libnss3 libasound2 libx11-6 libxext6 libxrender1 \
    build-essential \
 && update-ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# ---- Python deps
# (ensure requirements.txt is in repo root)
COPY requirements.txt .
RUN python -m pip install --upgrade pip setuptools wheel \
 && pip install -r requirements.txt

# ---- App code
COPY . .

# ---- Optional: Streamlit config (won't crash if file absent)
# Create the folder so Streamlit can write credentials/config
RUN mkdir -p /root/.streamlit
# If you have a config file, uncomment the next line and keep the path
# COPY .streamlit/config.toml /root/.streamlit/config.toml

# ---- Non-root for security
RUN useradd -m appuser
USER appuser

# ---- Networking
EXPOSE ${PORT}

# ---- Healthcheck (lightweight)
HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD curl -fsS http://127.0.0.1:${PORT}/ || exit 1

# ---- Start (Streamlit)
CMD ["streamlit", "run", "app.py", "--server.port=${PORT}", "--server.address=0.0.0.0"]
