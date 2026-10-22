def test_cheapest_market_for_crop(client):
    rows = client.get("/prices", params={"crop": "maize"}).json()
    expected = min(r["price_rwf_per_kg"] for r in rows)
    response = client.get("/prices/cheapest", params={"crop": "maize"})
    assert response.status_code == 200
    assert response.json()["price_rwf_per_kg"] == expected


def test_cheapest_unknown_crop_returns_404(client):
    response = client.get("/prices/cheapest", params={"crop": "gold"})
    assert response.status_code == 404
