from pydantic import BaseModel, Field


class Price(BaseModel):
    id: int
    crop: str
    market: str
    price_rwf_per_kg: int
    date: str


class PriceReport(BaseModel):
    crop: str = Field(min_length=1)
    market: str = Field(min_length=1)
    price_rwf_per_kg: int = Field(gt=0)
