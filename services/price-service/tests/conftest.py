import pytest
from fastapi.testclient import TestClient

from app import main
from app.repository import PriceRepository


@pytest.fixture
def client(monkeypatch):
    monkeypatch.setattr(main, "repository", PriceRepository())
    return TestClient(main.app)
