# ===== Runtime base (security-supported) =====
FROM python:3.11-slim-bookworm

# Make shell fail fast (safer for curl | sh) 
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Python settings
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Install system dependencies (patched) and refresh CA certs
RUN apt-get update \
 && apt-get -y upgrade \
 && apt-get install -y --no-install-recommends \
    curl ca-certificates bash nginx dos2unix \
    fonts-liberation libglib2.0-0 libnss3 libnspr4 \
    libatk1.0-0 libatk-bridge2.0-0 libcups2 libdbus-1-3 \
    libxkbcommon0 libxcomposite1 libxrandr2 libxdamage1 \
    libxfixes3 libdrm2 libgbm1 libasound2 libxshmfence1 \
    libpango-1.0-0 libcairo2 libx11-6 libxext6 \
    libx11-xcb1 libxcb1 \
 && update-ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# ---- Ollama (same install, but with safer curl flags) ----
# (Keeping functionality identical; if you later want pin+checksum, we can add that.)
RUN curl --fail --show-error --location --retry 3 https://ollama.com/install.sh | sh

WORKDIR /app

# Python requirements
COPY requirements.txt .
RUN python -m pip install --upgrade pip \
 && pip install --no-cache-dir -r requirements.txt

# Install Playwright (Chromium) + its system deps
RUN playwright install chromium \
 && playwright install-deps chromium

# Copy application files
COPY app.py main.py scraper.py resume_manager.py playwright_fetcher.py resume_parser.py query_to_filter.py backend_navigator.py ui.py entrypoint.sh ./
COPY assets/ ./assets
COPY cover_letter/ ./cover_letter
COPY styles.css ./

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Ensure entrypoint is UNIX format and executable
RUN dos2unix /app/*.sh && chmod +x /app/entrypoint.sh

# Environment variables (unchanged)
ENV MODEL_NAME=qwen2.5:0.5b \
    USE_OLLAMA=1 \
    OLLAMA_HOST=http://127.0.0.1:11434 \
    STREAMLIT_SERVER_PORT=5002 \
    STREAMLIT_SERVER_BASE_URL_PATH=team2f25 \
    BACKEND_PORT=8000

# Same exposed ports
EXPOSE 80 5002 11434

ENTRYPOINT ["./entrypoint.sh"]
