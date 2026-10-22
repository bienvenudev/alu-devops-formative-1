from fastapi import FastAPI, HTTPException

from app.models import Price, PriceReport
from app.repository import PriceRepository

app = FastAPI(title="Isoko Price Service", version="0.1.0")
repository = PriceRepository()


@app.get("/health")
def health():
    return {"status": "ok"}


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
    return repository.add(report)
