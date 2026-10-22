def test_health(client):
    assert client.get("/health").json() == {"status": "ok"}


def test_list_prices_returns_all(client):
    response = client.get("/prices")
    assert response.status_code == 200
    assert len(response.json()) == 20


def test_filter_by_crop_is_case_insensitive(client):
    rows = client.get("/prices", params={"crop": "BEANS"}).json()
    assert len(rows) == 4
    assert all(r["crop"] == "beans" for r in rows)


def test_filter_by_crop_and_market(client):
    rows = client.get("/prices", params={"crop": "maize", "market": "huye"}).json()
    assert len(rows) == 1
    assert rows[0]["market"] == "Huye"


def test_unknown_crop_returns_empty_list(client):
    response = client.get("/prices", params={"crop": "gold"})
    assert response.status_code == 200
    assert response.json() == []
