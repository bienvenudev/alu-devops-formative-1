
# [Project Name]

> [One-line tagline describing your project]

## African Context

[Explain what problem this solves and why it matters in an African context]

## Team Members

- [Name] - [Role] - [Student ID]
- [Name] - [Role] - [Student ID]
- [Name] - [Role] - [Student ID]

## Project Overview

[2-3 paragraph description of what this application does]

### Target Users
[Who will use this application?]

### Core Features
- Feature 1: [Description]
- Feature 2: [Description]
- Feature 3: [Description]

## Technology Stack

- **Backend**: [e.g., Python/Django, Node.js/Express]
- **Frontend**: [e.g., React, Vue, or vanilla JavaScript]
- **Database**: [e.g., PostgreSQL, MongoDB]
- **Other**: [Any other key technologies]

## Getting Started

### Prerequisites

- Python 3.12
- pip (comes with Python)
- Git

### Installation

1. Clone the repository

```bash
git clone https://github.com/bienvenudev/alu-devops-formative-1.git
cd alu-devops-formative-1
```

2. Go into the price service folder

```bash
cd services/price-service
```

3. Create and activate a virtual environment

```bash
python -m venv venv

# Windows
venv\Scripts\activate

# macOS / Linux
source venv/bin/activate
```

4. Install the dependencies

```bash
pip install -r requirements.txt
```

### Running the app

```bash
uvicorn app.main:app --reload
```

The API runs at `http://127.0.0.1:8000`. Interactive documentation is at `http://127.0.0.1:8000/docs`.

### Running the tests

```bash
pytest
```

### Usage

With the server running, call the API from a second terminal. On Windows PowerShell, type `curl.exe` instead of `curl`.

**Health check**

```bash
curl http://127.0.0.1:8000/health
```

**List all prices** (optional filters: `crop`, `market`)

```bash
curl http://127.0.0.1:8000/prices
curl "http://127.0.0.1:8000/prices?crop=beans&market=Huye"
```

**Cheapest price for a crop** (`crop` is required)

```bash
curl "http://127.0.0.1:8000/prices/cheapest?crop=beans"
```

**Report a new price**

```bash
curl -X POST http://127.0.0.1:8000/prices \
  -H "Content-Type: application/json" \
  -d '{"crop": "beans", "market": "Rubavu", "price_rwf_per_kg": 790}'
```

On Windows PowerShell, use this form instead:

```powershell
curl.exe -X POST http://127.0.0.1:8000/prices -H "Content-Type: application/json" -d '{\"crop\":\"beans\",\"market\":\"Rubavu\",\"price_rwf_per_kg\":790}'
```


## Project Structure
[Show your directory structure]

## Links

- [Project Board](link-to-github-projects)
- [Documentation](if applicable)

## License

[e.g., MIT License]