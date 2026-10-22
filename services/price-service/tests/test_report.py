def test_report_price_is_created_and_listed(client):
    payload = {"crop": "beans", "market": "Kimironko", "price_rwf_per_kg": 700}
    response = client.post("/prices", json=payload)
    assert response.status_code == 201
    assert response.json()["id"] == 21
    assert len(client.get("/prices").json()) == 21


def test_report_price_rejects_non_positive_price(client):
    payload = {"crop": "beans", "market": "Kimironko", "price_rwf_per_kg": 0}
    assert client.post("/prices", json=payload).status_code == 422


def test_report_price_rejects_missing_market(client):
    assert client.post("/prices", json={"crop": "beans", "price_rwf_per_kg": 500}).status_code == 422
