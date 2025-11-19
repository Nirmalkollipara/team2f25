# ===== Runtime base (slim, but with deps Streamlit/SSL need) =====
FROM python:3.11-slim-bookworm

# ---- Basic env & folders
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PORT=5002 \
    APP_HOME=/app
WORKDIR ${APP_HOME}

# ---- OS packages for Streamlit UI + HTTPS
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl \
    fonts-liberation fonts-dejavu-core \
    libnss3 libasound2 libx11-6 libxext6 libxrender1 \
 && update-ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# ---- Python deps
COPY requirements.txt .
RUN python -m pip install --upgrade pip setuptools wheel \
 && pip install --no-cache-dir -r requirements.txt

# ---- App code
COPY . .

# ---- Streamlit config folder (safe if absent)
RUN mkdir -p /root/.streamlit
# If you have a custom config.toml, uncomment the next line:
# COPY .streamlit/config.toml /root/.streamlit/config.toml

# ---- Networking
EXPOSE ${PORT}

# ---- Healthcheck: probe the correct subpath
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD curl -fsS http://127.0.0.1:${PORT}/team2f25/ || exit 1

# ---- Start (note the baseUrlPath so /team2f25 works)
CMD ["streamlit", "run", "app.py",
     "--server.port=5002",
     "--server.address=0.0.0.0",
     "--server.baseUrlPath=team2f25",
     "--browser.gatherUsageStats=false"]
