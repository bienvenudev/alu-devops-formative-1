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

## Technology Stack

| Area | Details |
| --- | --- |
| Backend | Python 3.10+, FastAPI, Uvicorn |
| Frontend | None yet (API with interactive docs at `/docs`) |
| Database | JSON file with sample data (a real database is planned) |
| Testing | pytest |
| Other | Git and GitHub (Projects, branch protection, pull requests). Docker and CI/CD are planned for Formative 2. |

## Getting Started

### Prerequisites

- Python 3.10 or newer
- git

### Installation

1. Clone the repository:

	```bash
	git clone https://github.com/bienvenudev/alu-devops-formative-1.git
	cd alu-devops-formative-1/services/price-service
	```

2. Create a virtual environment and install dependencies:

	```bash
	python3 -m venv venv
	source venv/bin/activate
	pip install -r requirements.txt
	```

### Run the Application

```bash
uvicorn app.main:app --reload
```

## Usage

Open <http://127.0.0.1:8000/docs> to try the API, or use curl:

```bash
curl "http://127.0.0.1:8000/prices?crop=beans&market=Kimironko"
curl "http://127.0.0.1:8000/prices/cheapest?crop=maize"
```

More detail, including testing and troubleshooting, is in `docs/setup.md`.

## Running the Tests

```bash
cd services/price-service
pytest
```

## Project Structure

```text
.
├── .github/                  # CODEOWNERS and PR template
├── docs/                     # Setup documentation
├── services/
│   └── price-service/        # Price API (one service, more planned)
│       ├── app/              # Routes, models, repository, sample data
│       ├── tests/            # pytest tests
│       └── requirements.txt
├── LICENSE
└── README.md
```
## Collaboration and Repository Security

**Branch protection on main:** a pull request is required, with at least 1 approval from someone other than the author. Stale approvals are dismissed when new commits are pushed, branches must be up to date before merging, conversations must be resolved, and the rules apply to administrators too. This prevents accidental direct pushes and makes sure every change is reviewed.

**Required status checks:** not enabled yet, because there is no CI pipeline. They will be added in Formative 2 once GitHub Actions runs the tests.

**Secrets:** `.gitignore` excludes `.env` files, keys and local config so credentials are never committed.

**Workflow:** every change is made on a branch, linked to an issue (`Closes #n`), and reviewed by a teammate.

## Links

- [Project Board](https://github.com/users/bienvenudev/projects/4)
- [Setup documentation](docs/setup.md)
- License

## License

MIT License. See [LICENSE](LICENSE).
