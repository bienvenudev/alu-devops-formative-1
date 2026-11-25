# Isoko

> Know the price before you go to market.

**Live application:** http://54.73.218.151 (`/docs` for the API, `/ready` for the readiness check; `terraform output app_url` prints the address)

Isoko is a small price service for crops in Rwandan markets, built as a complete DevOps project: it is provisioned with Terraform, configured with Ansible, checked by a CI pipeline with security scans, and deployed automatically to AWS by a CD pipeline on every merge to `main`.

## Contents

- [African Context](#african-context)
- [Team Members](#team-members)
- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Technology Stack](#technology-stack)
- [Getting Started](#getting-started)
- [Running with Docker](#running-with-docker)
- [CI/CD Pipeline](#cicd-pipeline)
- [Operations Manual](#operations-manual)
- [Security](#security)
- [Project Structure](#project-structure)
- [Collaboration and Repository Security](#collaboration-and-repository-security)
- [Links](#links)

## African Context

Smallholder farmers and small traders in Rwanda often sell and buy without knowing what the same crop costs in other markets such as Kimironko, Nyabugogo, Musanze or Huye. Without that information they can be underpaid, or travel far for a price that was not worth the trip. Price information exists but is scattered and hard to compare quickly.

Isoko (Kinyarwanda for "market") puts crop prices from several markets in one simple service, so people can compare prices and decide where to buy or sell.

## Team Members

- Bienvenu - Team Lead, price service core, repository security, Terraform registry, database and deployment modules, CD pipeline
- Victor - Backend tests, Terraform network and security modules, Ansible bastion role
- Adeline - Repository setup, Terraform compute module, Ansible security role
- Olive - Project documentation and planning board

Team roles, task tracker and meeting notes: [Team participation sheet](https://docs.google.com/spreadsheets/d/11OBOj6M3XrjWutGWa4VsuiRcg5KcznN2TqAo1Bzfnmw/edit?usp=sharing)

## Project Overview

Isoko is a small REST API that serves crop prices per market. A user can list prices, filter by crop and market, find the cheapest market for a crop, and report a new price. Prices are stored in PostgreSQL.

The service is built as a separate price service, so that later versions can add an SMS/USSD gateway and price alerts as their own services.

The prices in the sample data are illustrative, not real market prices.

### Target Users

- Smallholder farmers and farmer cooperatives deciding where to sell.
- Market traders and small retailers comparing buying prices.
- Households comparing food prices across markets.

### Core Features

- **View prices:** list crop prices per market.
- **Filter:** narrow results by crop and market.
- **Cheapest market:** find where a crop is cheapest.
- **Report a price:** add a new price observation with validation.
- **Health and readiness:** `/health` tells whether the service runs, `/ready` tells whether it can reach its database.
- **Planned:** access via USSD/SMS for users without smartphones.

## Architecture

```mermaid
flowchart LR
    user([User])
    dev([Developer])
    gh[GitHub repository]
    cd[GitHub Actions: CI and CD]
    ecr[(ECR private registry)]
    role[IAM role via OIDC]

    dev -->|pull request, merge to main| gh
    gh --> cd
    cd -->|assume role| role
    cd -->|push image| ecr
    cd -->|Ansible over SSH through the bastion| bastion

    user -->|HTTP port 80| bastion

    subgraph vpc [VPC 10.0.0.0/16 in eu-west-1]
        subgraph pub [Public subnet 10.0.1.0/24]
            bastion[Bastion and NAT instance with nginx]
        end
        subgraph priv [Private subnets 10.0.11.0/24 and 10.0.12.0/24]
            app[Application server: Docker, price-service]
            rds[(RDS PostgreSQL)]
        end
    end

    bastion -->|port 8000| app
    app -->|port 5432 with SSL| rds
    app -.->|pulls the image through the NAT| ecr
```

| Component | What it does |
| --- | --- |
| Bastion | The only server reachable from the internet. nginx forwards web traffic to the application server. SSH is allowed from one admin address (and from the pipeline runner, only while it deploys). It is also the NAT instance for the private subnets. |
| Application server | Runs the Isoko container with Docker Compose in a private subnet. It has no public address and only accepts traffic from the bastion. |
| RDS PostgreSQL | Stores the prices. It is in the private subnets, encrypted, and only accepts connections from the application server, over SSL. |
| ECR | Private registry for the container images. Each image is tagged with the git commit. |
| IAM role (OIDC) | Lets GitHub Actions log in to AWS without stored keys. It can only push to the registry, read the database secret and open SSH on the bastion. |
| Secrets Manager | Holds the database password. It is read by the pipeline and never written to the repository. |

**Why a NAT instance and no load balancer?** To keep the cost low. The bastion also forwards traffic for the private subnets, and nginx on the bastion is the public entry point. A managed NAT gateway (`create_nat_gateway = true`) and a load balancer with HTTPS would be better for production but cost more each day. See [Costs](#costs).

## Technology Stack

| Area | Details |
| --- | --- |
| Backend | Python 3.12, FastAPI, Uvicorn |
| Database | PostgreSQL 16 on Amazon RDS (a JSON file is used when no database is configured, for local runs and tests) |
| Testing | pytest, including tests against a real PostgreSQL |
| Containers | Docker, Docker Compose, Amazon ECR |
| Infrastructure | Terraform on AWS: VPC, EC2, RDS, ECR, IAM, Secrets Manager |
| Configuration | Ansible (roles `docker`, `app`, `bastion`, `security`) |
| CI/CD | GitHub Actions: ruff, pytest, pip-audit, Trivy, Checkov, ansible-lint |
| Collaboration | Git and GitHub: Projects, branch protection, pull requests |

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

### Run the application

```bash
uvicorn app.main:app --reload
```

Without a `DATABASE_URL` the service reads the sample prices from a JSON file. To use PostgreSQL, set the variable first, for example `export DATABASE_URL="postgresql://user:password@localhost:5432/isoko"`. The table is created and filled automatically.

### Usage

Open <http://127.0.0.1:8000/docs> to try the API, or use curl:

```bash
curl "http://127.0.0.1:8000/prices?crop=beans&market=Kimironko"
curl "http://127.0.0.1:8000/prices/cheapest?crop=maize"
curl http://127.0.0.1:8000/ready
```

More detail, including testing and troubleshooting, is in [docs/setup.md](docs/setup.md).

### Running the tests

```bash
cd services/price-service
pip install -r requirements-dev.txt
pytest
```

The tests that need PostgreSQL run only when `TEST_DATABASE_URL` is set, for example `postgresql://postgres:postgres@localhost:5432/postgres`.

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

On Windows Command Prompt use `copy .env.example .env`. The `.env` file is optional and never committed. The API is then available at <http://127.0.0.1:8000/docs>.

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

### Settings

| Variable | Default | Meaning |
| --- | --- | --- |
| `HOST_PORT` | `8000` | Port on your computer |
| `UVICORN_LOG_LEVEL` | `info` | Log detail (`debug`, `info`, `warning`) |

The Dockerfile is a multi-stage build on `python:3.12-slim`. The container runs as a non-root user and has a health check on `/health`.

## CI/CD Pipeline

### CI: checks on every pull request

The workflow [`ci.yml`](.github/workflows/ci.yml) runs on every push to a branch other than `main` and on every pull request to `main`. All eight jobs must pass before a pull request can be merged.

| Job | What it checks |
| --- | --- |
| `lint` | Python style with `ruff` |
| `test` | The `pytest` tests, with a real PostgreSQL |
| `docker-build` | Builds the Docker image and checks that the container answers on `/health` |
| `dependency-scan` | Known vulnerabilities in the Python packages (`pip-audit`) |
| `image-scan` | HIGH and CRITICAL vulnerabilities in the Docker image (Trivy). The build fails if it finds one that has a fix. |
| `iac-scan` | Risky settings in the Terraform files (Checkov) |
| `terraform-validate` | Terraform formatting, and validation of every module and of the root configuration |
| `ansible-check` | Ansible syntax and style (`ansible-lint`) |

### CD: deployment on every merge to main

The workflow [`cd.yml`](.github/workflows/cd.yml) runs when a pull request is merged into `main`:

1. **`ci`** runs all eight CI jobs again on the merged code.
2. **`build-and-push`** logs in to AWS through OIDC, builds the image, scans it with Trivy, and pushes it to the private registry with the git commit as the tag.
3. **`deploy`** opens SSH on the bastion for the runner's address only, collects the registry token and the database password, runs the Ansible playbook through the bastion, checks that the live service answers on `/ready` and `/prices/cheapest`, and then closes SSH again and removes the temporary secret files.

After a deployment, the `version` field returned by `/ready` is the git commit that is running, so it should equal the commit that was just merged.

Only one deployment runs at a time. The pipeline fails, and the old version keeps running, if a check, the scan, the push or the playbook fails.

## Operations Manual

### First-time setup

Only the team lead does this, on a machine with the AWS CLI, Terraform and Ansible. The details are in [terraform/README.md](terraform/README.md) and [ansible/README.md](ansible/README.md).

1. Log in to AWS and create `terraform/terraform.tfvars` from `terraform.tfvars.example`.
2. `terraform init`, `terraform plan`, `terraform apply`.
3. Save the outputs in GitHub as repository variables and the private SSH key as the secret `DEPLOY_SSH_KEY` (the script `scripts/set-github-config.sh` does this).
4. Merge a pull request to `main`. The CD pipeline builds, pushes and deploys.

### Deploy a change

Open a pull request, wait for the eight checks, get an approval and merge. The CD pipeline does the rest. The version running in production is the git commit shown by:

```bash
curl http://<bastion-ip>/ready
```

### Check the health of the system

| Signal | Command | Healthy answer |
| --- | --- | --- |
| Is the proxy up? | `curl http://<bastion-ip>/nginx-health` | `ok` |
| Is the service up? | `curl http://<bastion-ip>/health` | `{"status":"ok"}` |
| Can it reach its database? | `curl http://<bastion-ip>/ready` | `{"status":"ready","repository":"postgres","version":"<commit>"}`. A `503` means the database is not reachable. |
| What is it doing? | `docker logs --tail 50 isoko-price-service-1` on the application server | one line per start, price report and error |
| Is the container healthy? | `docker ps` on the application server | `(healthy)` |

To reach the application server, connect through the bastion (your address must be in `allowed_ssh_cidr`):

```bash
ssh -i ~/.ssh/isoko-key -o ProxyCommand="ssh -W %h:%p -q -i ~/.ssh/isoko-key ubuntu@<bastion-ip>" ubuntu@<app-private-ip>
```

### Roll back

Revert the pull request that broke production. The revert is a normal pull request, and its merge deploys the previous code. Images stay in the registry (the last ten are kept).

### Rotate the database password

The password is created by Terraform and is not rotated automatically, so that an automatic rotation can never break a running service. To change it, run `terraform apply -replace=module.database.random_password.db`. This generates a new password, applies it to the database and stores it in Secrets Manager. Then re-run the CD workflow so that the new password reaches the server.

### Costs

Approximate prices for `eu-west-1`, in USD (check the AWS pricing pages for exact values):

| Setup | Per day |
| --- | --- |
| This project: two `t3.micro` servers, one `db.t3.micro`, the NAT instance on the bastion | about 1.3 |
| With a managed NAT gateway (`create_nat_gateway = true`) | about 2.5 |
| Adding an Application Load Balancer | about 0.6 more |

The cheap setup was chosen on purpose and is documented as a trade-off. Run `terraform destroy` when the system is not needed.

### Remove everything

```bash
cd terraform
terraform destroy
```

### Troubleshooting

| Problem | Likely cause and fix |
| --- | --- |
| `/ready` returns `503` | The database is not reachable. Check that the database is `available` in the RDS console, and that the application server security group can reach port 5432. |
| The deploy job fails at `Open SSH on the bastion` | The AWS role is not allowed, or the repository variables are missing. Check `BASTION_SG_ID` and `AWS_ROLE_ARN`. |
| The playbook cannot reach the application server | The bastion is not reachable or its NAT is down. Run `ansible all -m ping` from `ansible/` with `BASTION_PUBLIC_IP` and `APP_PRIVATE_IP` set. |
| The private server has no internet | The NAT instance is down. On the bastion, check `sysctl net.ipv4.ip_forward` (must be 1) and `sudo iptables -t nat -S`. |
| `image-scan` fails on an unchanged branch | A new vulnerability was published. Update the base image or the package. See [SECURITY.md](SECURITY.md). |
| Terraform cannot find credentials after `aws login` | Terraform does not read `aws login` sessions. Run `eval "$(aws configure export-credentials --format env)"` first. |

## Security

- Shift-left scans in every pull request: dependencies, the Docker image and the Terraform code. Findings and accepted risks are in [SECURITY.md](SECURITY.md).
- The application server and the database are in private subnets. The only public ports are 80 and, for one address, 22 on the bastion.
- SSH uses keys only, root login is off, and fail2ban is active.
- No secrets in the repository. The database password is in Secrets Manager, and the pipeline uses short-lived AWS credentials.

## Project Structure

```text
.
├── .github/
│   ├── workflows/
│   │   ├── ci.yml                # Checks on every pull request
│   │   └── cd.yml                # Build, push and deploy on every merge to main
│   ├── CODEOWNERS
│   └── pull_request_template.md
├── ansible/
│   ├── inventory/hosts.yml       # Bastion and application server
│   ├── group_vars/               # Settings per server type
│   ├── roles/                    # docker, app, bastion, security
│   └── site.yml                  # The playbook
├── docs/                         # Setup documentation and team contract
├── scripts/                      # Helper to store the Terraform outputs in GitHub
├── services/
│   └── price-service/            # Price API
│       ├── app/                  # Routes, models, repositories, sample data
│       ├── tests/                # pytest tests
│       ├── requirements.txt      # runtime dependencies
│       └── requirements-dev.txt  # tests and linting
├── terraform/
│   ├── modules/                  # network, security, compute, database, registry, github_oidc
│   ├── main.tf                   # Connects the modules
│   ├── variables.tf
│   └── outputs.tf
├── CHANGELOG.md                  # What changed in F1, F2, F3 and the Summative
├── Dockerfile
├── SECURITY.md                   # Security scans, findings and accepted risks
├── docker-compose.yml            # Local development
├── ruff.toml
├── LICENSE
└── README.md
```

## Collaboration and Repository Security

**Branch protection on main:** a pull request is required, with at least 1 approval from someone other than the author. Stale approvals are dismissed when new commits are pushed, conversations must be resolved, and the rules apply to administrators too. Branches must be up to date with `main` before merging, so the checks always run against the latest code. This prevents accidental direct pushes and makes sure every change is reviewed.

**Required status checks:** the CI jobs `lint`, `test`, `docker-build`, `dependency-scan`, `image-scan`, `iac-scan`, `terraform-validate` and `ansible-check` must pass before a pull request can be merged. This blocks style errors, failing tests, a broken Docker build, vulnerable dependencies or images, and risky infrastructure settings from reaching `main`.

**Secrets:** `.gitignore` excludes `.env` files, keys, Terraform state and local config so credentials are never committed.

**Workflow:** every change is made on a branch, linked to an issue (`Closes #n`), and reviewed by a teammate.

## Links

- [Project Board](https://github.com/users/bienvenudev/projects/4)
- [Changelog](CHANGELOG.md)
- [Setup documentation](docs/setup.md)
- [Terraform guide](terraform/README.md)
- [Ansible guide](ansible/README.md)
- [Security](SECURITY.md)
- [Team participation sheet](https://docs.google.com/spreadsheets/d/11OBOj6M3XrjWutGWa4VsuiRcg5KcznN2TqAo1Bzfnmw/edit?usp=sharing)
- [License](LICENSE)

## License

MIT License. See [LICENSE](LICENSE).
