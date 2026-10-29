# Build stage: install the Python packages into their own folder
FROM python:3.12-slim AS builder
WORKDIR /build
COPY services/price-service/requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Final stage: a small image that only holds the packages and the app code
FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app
COPY --from=builder /install /usr/local
COPY services/price-service/app ./app
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
