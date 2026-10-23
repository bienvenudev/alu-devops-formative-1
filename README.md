# Isoko

> Know the price before you go to market.

## African Context

Smallholder farmers and small traders in Rwanda often sell and buy without knowing what the same crop costs in other markets such as Kimironko, Nyabugogo, Musanze or Huye. Without that information they can be underpaid, or travel far for a price that was not worth the trip. Price information exists but is scattered and hard to compare quickly.

Isoko (Kinyarwanda for "market") puts crop prices from several markets in one simple service, so people can compare prices and decide where to buy or sell.

## Team Members

- Bienvenu - Team Lead, price service core, repository security
- Victor - Backend: cheapest-market, price reporting, tests
- Adeline - Repository setup (.gitignore, CODEOWNERS) and setup documentation
- Olive - Project documentation and planning board

## Project Overview

Isoko is a small REST API that serves crop prices per market. A user can list prices, filter by crop and market, find the cheapest market for a crop, and report a new price.

The first version is intentionally small. It runs on sample data and is built as a separate price service, so that later versions can add an SMS/USSD gateway and price alerts as their own services, and the whole system can be containerized and deployed to the cloud.

The prices in the sample data are illustrative, not real market prices.

## Target Users

- Smallholder farmers and farmer cooperatives deciding where to sell.
- Market traders and small retailers comparing buying prices.
- Households comparing food prices across markets.

## Core Features

- **View prices:** list crop prices per market.
- **Filter:** narrow results by crop and market.
- **Cheapest market:** find where a crop is cheapest.
- **Report a price:** add a new price observation with validation.
- **Planned:** access via USSD/SMS for users without smartphones.
