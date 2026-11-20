from psycopg import OperationalError

from app import main


def test_ready_with_json_repository(client):
    response = client.get("/ready")
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ready"
    assert body["repository"] == "json"


def test_ready_returns_503_when_database_is_down(client, monkeypatch):
    def broken_ping():
        raise OperationalError("connection refused")

    monkeypatch.setattr(main.repository, "ping", broken_ping)
    response = client.get("/ready")
    assert response.status_code == 503
    assert response.json()["status"] == "not ready"


def test_prices_returns_503_when_database_is_down(client, monkeypatch):
    def broken_list(crop=None, market=None):
        raise OperationalError("connection refused")

    monkeypatch.setattr(main.repository, "list_prices", broken_list)
    response = client.get("/prices")
    assert response.status_code == 503
    assert response.json() == {"detail": "Database unavailable"}


def test_health_stays_ok_when_database_is_down(client, monkeypatch):
    def broken_ping():
        raise OperationalError("connection refused")

    monkeypatch.setattr(main.repository, "ping", broken_ping)
    assert client.get("/health").json() == {"status": "ok"}
