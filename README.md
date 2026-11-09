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

Team roles, task tracker and meeting notes: [Team participation sheet](https://docs.google.com/spreadsheets/d/11OBOj6M3XrjWutGWa4VsuiRcg5KcznN2TqAo1Bzfnmw/edit?usp=sharing)

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
| Other | Git and GitHub (Projects, branch protection, pull requests). Docker and CI/CD are planned as next steps. |

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

More detail, including testing and troubleshooting, is in [docs/setup.md](docs/setup.md).

## Running the Tests

```bash
cd services/price-service
pip install -r requirements-dev.txt
pytest
```

## Running with Docker

### Prerequisites

- Docker Desktop (Windows/macOS) or Docker Engine with the Compose plugin (Linux)
- Check the installation: `docker --version` and `docker compose version`

### Start the service

From the repository root:

```bash
cp .env.example .env
docker compose up --build
```

On Windows Command Prompt use `copy .env.example .env`. The `.env` file is optional and never committed.

The API is then available at <http://127.0.0.1:8000/docs>.

### Check that it works

```bash
curl http://127.0.0.1:8000/health
docker compose ps
```

The first command returns `{"status":"ok"}`. `docker compose ps` shows the container as `healthy` after a few seconds.

### Stop the service

```bash
docker compose down
```

Use `docker compose down -v` to also delete the data volume.

### Settings

| Variable | Default | Meaning |
| --- | --- | --- |
| `HOST_PORT` | `8000` | Port on your computer |
| `UVICORN_LOG_LEVEL` | `info` | Log detail (`debug`, `info`, `warning`) |

### About the image

The Dockerfile is a multi-stage build on `python:3.12-slim`. The container runs as a non-root user and has a health check on `/health`.

## Continuous Integration

The workflow in `.github/workflows/ci.yml` runs on every push to a branch other than `main` and on every pull request to `main`. It has eight jobs:

| Job | What it checks |
| --- | --- |
| `lint` | Python style with `ruff` |
| `test` | The `pytest` tests |
| `docker-build` | Builds the Docker image and checks that the container answers on `/health` |
| `dependency-scan` | Known vulnerabilities in the Python packages (`pip-audit`) |
| `image-scan` | Known vulnerabilities in the Docker image (Trivy) |
| `iac-scan` | Risky settings in the Terraform files (Checkov) |
| `terraform-validate` | Terraform formatting and syntax |
| `ansible-check` | Ansible syntax and style (`ansible-lint`) |

All of them must pass before a pull request can be merged into `main`. Our findings and how we fixed them are in [SECURITY.md](SECURITY.md).

## Infrastructure and Deployment

The infrastructure is described as code, in two steps:

1. **Terraform** (`terraform/`) creates the AWS resources: a VPC with a public subnet, internet gateway and route table, a security group, and one Ubuntu server with an Elastic IP. See [terraform/README.md](terraform/README.md).
2. **Ansible** (`ansible/`) configures that server: it installs Docker, deploys the service with `docker compose`, and secures the server with a firewall and SSH hardening. See [ansible/README.md](ansible/README.md).

In short, `terraform apply` creates the server, then `ansible-playbook` makes it run Isoko. Security scans (dependencies, Docker image and Terraform) run in CI on every pull request. Their findings are documented in [SECURITY.md](SECURITY.md).

## Project Structure

```text
.
├── .github/
│   ├── workflows/ci.yml          # CI pipeline (lint, test, Docker build)
│   ├── CODEOWNERS
│   └── pull_request_template.md
├── docs/                         # Setup documentation
├── services/
│   └── price-service/            # Price API (one service, more planned)
│       ├── app/                  # Routes, models, repository, sample data
│       ├── tests/                # pytest tests
│       ├── requirements.txt      # runtime dependencies
│       └── requirements-dev.txt  # tests and linting
├── .dockerignore
├── .env.example
├── Dockerfile
├── docker-compose.yml
├── ruff.toml
├── LICENSE
└── README.md
```

## Collaboration and Repository Security

**Branch protection on main:** a pull request is required, with at least 1 approval from someone other than the author. Stale approvals are dismissed when new commits are pushed, conversations must be resolved, and the rules apply to administrators too. Branches must be up to date with `main` before merging, so the checks always run against the latest code. This prevents accidental direct pushes and makes sure every change is reviewed.

**Required status checks:** the CI jobs `lint`, `test` and `docker-build` must pass before a pull request can be merged. This blocks code with style errors, failing tests or a broken Docker build from reaching `main`.

**Secrets:** `.gitignore` excludes `.env` files, keys and local config so credentials are never committed.

**Workflow:** every change is made on a branch, linked to an issue (`Closes #n`), and reviewed by a teammate.

## Links

- [Project Board](https://github.com/users/bienvenudev/projects/4)
- [Setup documentation](docs/setup.md)
- [Team participation sheet](https://docs.google.com/spreadsheets/d/11OBOj6M3XrjWutGWa4VsuiRcg5KcznN2TqAo1Bzfnmw/edit?usp=sharing)
- [License](LICENSE)

## License

MIT License. See [LICENSE](LICENSE).
