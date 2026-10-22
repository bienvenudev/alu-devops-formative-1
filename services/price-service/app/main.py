from fastapi import FastAPI

from app.models import Price
from app.repository import PriceRepository

app = FastAPI(title="Isoko Price Service", version="0.1.0")
repository = PriceRepository()


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/prices", response_model=list[Price])
def list_prices(crop: str | None = None, market: str | None = None):
    return repository.list_prices(crop=crop, market=market)
