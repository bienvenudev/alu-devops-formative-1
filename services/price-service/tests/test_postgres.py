import os

import pytest

from app.models import PriceReport

DATABASE_URL = os.getenv("TEST_DATABASE_URL")

pytestmark = pytest.mark.skipif(
    not DATABASE_URL, reason="TEST_DATABASE_URL is not set, so no PostgreSQL is available"
)


@pytest.fixture
def pg_repository():
    import psycopg

    from app.postgres_repository import PostgresPriceRepository

    with psycopg.connect(DATABASE_URL, autocommit=True) as conn:
        conn.execute("DROP TABLE IF EXISTS prices")
    return PostgresPriceRepository(DATABASE_URL)


def test_table_is_created_and_seeded(pg_repository):
    assert pg_repository.ping() is True
    assert len(pg_repository.list_prices()) == 20


def test_seed_runs_only_once(pg_repository):
    from app.postgres_repository import PostgresPriceRepository

    pg_repository.ping()
    second = PostgresPriceRepository(DATABASE_URL)
    assert len(second.list_prices()) == 20


def test_filter_is_case_insensitive(pg_repository):
    rows = pg_repository.list_prices(crop="BEANS", market="huye")
    assert len(rows) == 1
    assert rows[0].market == "Huye"


def test_unknown_crop_returns_empty_list(pg_repository):
    assert pg_repository.list_prices(crop="gold") == []


def test_cheapest_matches_lowest_price(pg_repository):
    lowest = min(p.price_rwf_per_kg for p in pg_repository.list_prices(crop="maize"))
    assert pg_repository.cheapest("MAIZE").price_rwf_per_kg == lowest
    assert pg_repository.cheapest("gold") is None


def test_add_is_stored_and_listed(pg_repository):
    created = pg_repository.add(
        PriceReport(crop="beans", market="Kimironko", price_rwf_per_kg=700)
    )
    assert created.id == 21
    assert len(pg_repository.list_prices()) == 21
    assert pg_repository.cheapest("beans").price_rwf_per_kg == 700


def test_api_uses_postgres(monkeypatch, pg_repository):
    from fastapi.testclient import TestClient

    from app import main

    monkeypatch.setattr(main, "repository", pg_repository)
    client = TestClient(main.app)
    assert client.get("/ready").json()["repository"] == "postgres"
    response = client.post(
        "/prices", json={"crop": "beans", "market": "Huye", "price_rwf_per_kg": 650}
    )
    assert response.status_code == 201
    cheapest = client.get("/prices/cheapest", params={"crop": "beans"}).json()
    assert cheapest["price_rwf_per_kg"] == 650
