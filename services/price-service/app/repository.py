import json
from datetime import date
from pathlib import Path

from app.models import Price, PriceReport

DATA_FILE = Path(__file__).parent / "data" / "prices.json"


class PriceRepository:
    """Loads prices from a JSON file and answers queries about them."""

    def __init__(self, data_file: Path = DATA_FILE):
        with open(data_file, encoding="utf-8") as f:
            self._prices = [Price(**row) for row in json.load(f)]

    def list_prices(self, crop: str | None = None, market: str | None = None) -> list[Price]:
        results = self._prices
        if crop:
            results = [p for p in results if p.crop.lower() == crop.lower()]
        if market:
            results = [p for p in results if p.market.lower() == market.lower()]
        return results

    def cheapest(self, crop: str) -> Price | None:
        matches = self.list_prices(crop=crop)
        return min(matches, key=lambda p: p.price_rwf_per_kg) if matches else None

    def add(self, report: PriceReport) -> Price:
        price = Price(
            id=max((p.id for p in self._prices), default=0) + 1,
            date=date.today().isoformat(),
            **report.model_dump(),
        )
        self._prices.append(price)
        return price
