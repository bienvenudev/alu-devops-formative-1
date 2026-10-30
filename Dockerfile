# Use a pinned, small Python image for predictable dependency builds.
FROM python:3.12-slim AS builder

# Install dependencies into a self-contained virtual environment.
WORKDIR /build
COPY services/price-service/requirements.txt ./requirements.txt
RUN python -m venv /opt/venv \
    && /opt/venv/bin/pip install --no-cache-dir --disable-pip-version-check -r requirements.txt

# Start the runtime image from the same pinned base without build tooling.
FROM python:3.12-slim AS runtime

# Keep Python output immediate and avoid writing bytecode into the image.
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Run the service as an unprivileged user.
RUN groupadd --system app && useradd --system --gid app --create-home app

# Reuse the dependency environment produced by the builder stage.
WORKDIR /app/services/price-service
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy only the application source and its sample data into the runtime image.
COPY services/price-service/app ./app

# Store the service data under a path that Compose can persist with a named volume.
RUN chown -R app:app /app
VOLUME ["/app/services/price-service/app/data"]
USER app

# Document and verify the API endpoint used by the container healthcheck.
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=3)"

# Start the API server when the container launches.
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
