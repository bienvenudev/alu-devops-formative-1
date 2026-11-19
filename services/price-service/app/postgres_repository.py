import json
from datetime import date
from pathlib import Path

from psycopg.rows import dict_row
from psycopg_pool import ConnectionPool

from app.models import Price, PriceReport
from app.repository import DATA_FILE

SCHEMA = """
CREATE TABLE IF NOT EXISTS prices (
    id SERIAL PRIMARY KEY,
    crop TEXT NOT NULL,
    market TEXT NOT NULL,
    price_rwf_per_kg INTEGER NOT NULL CHECK (price_rwf_per_kg > 0),
    date DATE NOT NULL
)
"""

COLUMNS = "id, crop, market, price_rwf_per_kg, date"


def _to_price(row: dict) -> Price:
    return Price(**{**row, "date": row["date"].isoformat()})


class PostgresPriceRepository:
    """Stores prices in PostgreSQL. The table is created and seeded on first use."""

    name = "postgres"

    def __init__(self, conninfo: str, seed_file: Path = DATA_FILE):
        self._seed_file = seed_file
        self._ready = False
        self._pool = ConnectionPool(
            conninfo,
            min_size=1,
            max_size=5,
            timeout=5,
            kwargs={"row_factory": dict_row},
            open=True,
        )

    def _ensure_schema(self) -> None:
        if self._ready:
            return
        with self._pool.connection() as conn:
            conn.execute(SCHEMA)
            count = conn.execute("SELECT count(*) AS n FROM prices").fetchone()["n"]
            if count == 0:
                with open(self._seed_file, encoding="utf-8") as f:
                    rows = json.load(f)
                conn.cursor().executemany(
                    "INSERT INTO prices (crop, market, price_rwf_per_kg, date) "
                    "VALUES (%(crop)s, %(market)s, %(price_rwf_per_kg)s, %(date)s)",
                    rows,
                )
        self._ready = True

    def ping(self) -> bool:
        self._ensure_schema()
        with self._pool.connection() as conn:
            conn.execute("SELECT 1")
        return True

    def list_prices(self, crop: str | None = None, market: str | None = None) -> list[Price]:
        self._ensure_schema()
        with self._pool.connection() as conn:
            rows = conn.execute(
                f"SELECT {COLUMNS} FROM prices "
                "WHERE (%(crop)s::text IS NULL OR lower(crop) = lower(%(crop)s)) "
                "AND (%(market)s::text IS NULL OR lower(market) = lower(%(market)s)) "
                "ORDER BY id",
                {"crop": crop or None, "market": market or None},
            ).fetchall()
        return [_to_price(row) for row in rows]

    def cheapest(self, crop: str) -> Price | None:
        self._ensure_schema()
        with self._pool.connection() as conn:
            row = conn.execute(
                f"SELECT {COLUMNS} FROM prices WHERE lower(crop) = lower(%s) "
                "ORDER BY price_rwf_per_kg, id LIMIT 1",
                (crop,),
            ).fetchone()
        return _to_price(row) if row else None

    def add(self, report: PriceReport) -> Price:
        self._ensure_schema()
        with self._pool.connection() as conn:
            row = conn.execute(
                "INSERT INTO prices (crop, market, price_rwf_per_kg, date) "
                f"VALUES (%s, %s, %s, %s) RETURNING {COLUMNS}",
                (report.crop, report.market, report.price_rwf_per_kg, date.today()),
            ).fetchone()
        return _to_price(row)
