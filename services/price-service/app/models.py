from pydantic import BaseModel


class Price(BaseModel):
    id: int
    crop: str
    market: str
    price_rwf_per_kg: int
    date: str
