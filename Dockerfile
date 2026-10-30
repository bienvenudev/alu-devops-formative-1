# Build stage: install the Python packages into their own folder
FROM python:3.12-slim AS builder
WORKDIR /build
# Copy requirements first so Docker can reuse this layer when only the code changes
COPY services/price-service/requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Final stage: a small image that only holds the packages and the app code
FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
# Run as a normal user instead of root
RUN useradd --create-home --uid 10001 appuser
WORKDIR /app
COPY --from=builder /install /usr/local
COPY services/price-service/app ./app
USER appuser
EXPOSE 8000
# Docker marks the container unhealthy if /health stops answering
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health')"
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
