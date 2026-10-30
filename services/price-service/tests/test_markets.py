import pytest

MARKETS = ["Kimironko", "Nyabugogo", "Musanze", "Huye"]


@pytest.mark.parametrize("market", MARKETS)
def test_each_market_lists_five_crops(client, market):
    rows = client.get("/prices", params={"market": market}).json()
    assert len(rows) == 5
