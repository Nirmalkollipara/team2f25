# ---------- Builder: build wheels so we don't ship dev tools ----------
FROM python:3.11-slim-bookworm AS builder

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install minimal build tools for any dependencies that need compiling
RUN apt-get update \
 && apt-get install -y --no-install-recommends build-essential \
 && rm -rf /var/lib/apt/lists/*

# Install and build dependency wheels
COPY requirements.txt .
RUN python -m pip install --upgrade pip setuptools wheel \
 && pip wheel --no-cache-dir -r requirements.txt -w /wheels


# ---------- Runtime: smaller, patched OS + only final deps ----------
# Replace <PUT_CURRENT_DIGEST_HERE> with the actual digest for reproducibility
FROM python:3.11-slim-bookworm@sha256:<PUT_CURRENT_DIGEST_HERE>

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Add non-root user
RUN adduser --disabled-password --gecos "" appuser

# Pull latest OS security patches (safe, small)
RUN apt-get update \
 && apt-get -y upgrade \
 && rm -rf /var/lib/apt/lists/*

# Copy prebuilt wheels and install them cleanly
COPY --from=builder /wheels /wheels
RUN pip install --no-cache-dir /wheels/*.whl \
 && rm -rf /wheels

# Copy your application source
COPY . .

# Drop privileges
USER appuser

# Expose port (Streamlit default = 5002)
EXPOSE 5002

# Start your app (adjust this command if needed)
CMD ["streamlit", "run", "app.py", "--server.port=5002", "--server.address=0.0.0.0"]
