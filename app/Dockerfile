# ── Stage 1: builder ───────────────────────────────────────────────────────
FROM python:3.13-slim AS builder

# Don't write .pyc files and don't cache pip downloads (keeps things lean).
ENV PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /build

# Install runtime dependencies into an isolated virtualenv we can copy later.
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt


# ── Stage 2: runtime (the image we actually ship) ──────────────────────────
FROM python:3.13-slim AS runtime

# PYTHONUNBUFFERED makes logs appear immediately (important for container logs).
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/opt/venv/bin:$PATH"

# SECURITY: create and run as a non-root user. If the app is ever compromised,
# the attacker is not root inside the container.
RUN groupadd --system appgroup && \
    useradd --system --gid appgroup --no-create-home appuser

WORKDIR /app

# Copy the pre-built virtualenv from the builder stage.
COPY --from=builder /opt/venv /opt/venv

# Copy only the application source (see .dockerignore for what's excluded).
COPY app ./app

# Drop privileges.
USER appuser

# Document the port the app listens on.
EXPOSE 8000

# HEALTHCHECK: Docker/Azure periodically run this to confirm the app is healthy.
# We use Python's stdlib (no curl needed) so we don't add extra packages.
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request,sys; \
        sys.exit(0) if urllib.request.urlopen('http://127.0.0.1:8000/health').status==200 else sys.exit(1)"

# Start the ASGI server. Host 0.0.0.0 so it's reachable from outside the container.
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
