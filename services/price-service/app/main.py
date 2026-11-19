import logging
import os

from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
from psycopg import OperationalError
from psycopg_pool import PoolTimeout

from app.models import Price, PriceReport
from app.repository import create_repository

APP_VERSION = os.getenv("APP_VERSION", "dev")

logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO").upper(),
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)
logger = logging.getLogger("isoko")

app = FastAPI(title="Isoko Price Service", version=APP_VERSION)
repository = create_repository()
logger.info("starting version=%s repository=%s", APP_VERSION, repository.name)


@app.exception_handler(OperationalError)
@app.exception_handler(PoolTimeout)
def database_unavailable(request, exc):
    logger.error("database unavailable: %s", exc)
    return JSONResponse(status_code=503, content={"detail": "Database unavailable"})


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/ready")
def ready():
    try:
        repository.ping()
    except (OperationalError, PoolTimeout) as exc:
        logger.error("readiness check failed: %s", exc)
        return JSONResponse(
            status_code=503,
            content={"status": "not ready", "repository": repository.name, "version": APP_VERSION},
        )
    return {"status": "ready", "repository": repository.name, "version": APP_VERSION}


@app.get("/prices", response_model=list[Price])
def list_prices(crop: str | None = None, market: str | None = None):
    return repository.list_prices(crop=crop, market=market)


@app.get("/prices/cheapest", response_model=Price)
def cheapest_price(crop: str):
    price = repository.cheapest(crop)
    if price is None:
        raise HTTPException(status_code=404, detail=f"No prices found for crop '{crop}'")
    return price


@app.post("/prices", response_model=Price, status_code=201)
def report_price(report: PriceReport):
    price = repository.add(report)
    logger.info("price reported id=%s crop=%s market=%s", price.id, price.crop, price.market)
    return price
