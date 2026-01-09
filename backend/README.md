# Backend (Django + DRF)

## Run locally (Docker)
1) Copy `.env.example` to `.env` and adjust values as needed.
2) Start services:

```bash
cd backend
docker compose up --build
```

API docs: `http://localhost:8000/api/docs`

## Run tests
```bash
cd backend
pip install -e .[dev]
python -m pytest
```

If you run tests outside Docker, update `.env` to use `localhost`:
```
DATABASE_URL=postgres://smart_trip_planner:smart_trip_planner@localhost:5432/smart_trip_planner
```

Or run tests inside Docker (uses `db` host):
```bash
cd backend
docker compose run --rm api python -m pytest
```

## Lint/format
```bash
cd backend
ruff check .
black .
```
