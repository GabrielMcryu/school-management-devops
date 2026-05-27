# syntax=docker/dockerfile:1
FROM python:3.12-alpine

# Copy the uv binary from the official image
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy

WORKDIR /app

# Install dependencies first (cached layer) using the lockfile
COPY pyproject.toml uv.lock ./
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-install-project --no-dev

# Copy the application source
COPY . .

# Install the project itself
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev

ENV PATH="/app/.venv/bin:$PATH"

# Collect static files into STATIC_ROOT for WhiteNoise to serve.
# SECRET_KEY is a throwaway value used only for this build step (no DB access).
RUN SECRET_KEY=build-time-only python manage.py collectstatic --noinput

# Run as a non-root user
RUN adduser -D -u 1000 appuser \
    && chown -R appuser:appuser /app
USER appuser

EXPOSE 8000

# Apply migrations on startup, then serve via gunicorn (production WSGI server).
CMD ["sh", "-c", "python manage.py migrate --noinput && gunicorn core.wsgi:application --bind 0.0.0.0:8000 --workers 3"]
