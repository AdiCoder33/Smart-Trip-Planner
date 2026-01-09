# Backend (Django + DRF)

## Run locally (Docker)
1) Copy `.env.example` to `.env` and adjust values as needed.
2) Start services:

```bash
cd backend
docker compose up --build
```

API docs: `http://localhost:8000/api/docs`

## Email invites
Default email backend is console (emails show in logs). For SMTP, set:
```
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=smtp.example.com
EMAIL_PORT=587
EMAIL_HOST_USER=your-user
EMAIL_HOST_PASSWORD=your-password
EMAIL_USE_TLS=1
DEFAULT_FROM_EMAIL=no-reply@your-domain.com
```

Invite emails include a token to paste into the app's Accept Invite screen.

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
