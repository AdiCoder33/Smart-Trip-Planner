# Backend (Django + DRF)

## Run locally (Docker)
1) Copy `.env.example` to `.env` and adjust values as needed.
2) Start services:

```bash
cd backend
docker compose up --build
```

API docs: `http://localhost:8000/api/docs`

## Chat (WebSocket + REST)
WebSocket endpoint:
```
ws://localhost:8000/ws/trips/<trip_id>/chat/?token=<JWT_ACCESS>
```

Send payload:
```
{"type":"message","content":"Hello","client_id":"<uuid>"}
```

Receive payload:
```
{
  "type":"message",
  "message":{
    "id":"...",
    "trip_id":"...",
    "sender":{"id":"...","name":"..."},
    "content":"...",
    "encrypted_content":"...",
    "encryption_version":1,
    "client_id":"...",
    "created_at":"ISO8601"
  }
}
```

REST history:
```
GET /api/trips/<trip_id>/chat/messages?limit=50&before=<ISO8601>
```

REST send (also broadcasts to WebSocket group):
```
POST /api/trips/<trip_id>/chat/messages
{ "content": "Hello", "client_id": "<uuid>" }
```

Chat key (used for encrypted payloads):
```
GET /api/trips/<trip_id>/chat/key
```

## Expenses
Create/list expenses:
```
GET /api/trips/<trip_id>/expenses
POST /api/trips/<trip_id>/expenses
```

Summary per member:
```
GET /api/trips/<trip_id>/expenses/summary
```

## Calendar export
Export itinerary as ICS:
```
GET /api/trips/<trip_id>/calendar
```

For mobile download, append a token:
```
GET /api/trips/<trip_id>/calendar?token=<JWT_ACCESS>
```

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

## Itinerary date field
Itinerary items use an optional `date` field (YYYY-MM-DD) to group items by day.

## Deploy on Render
1) Create a new Web Service from this repo.
2) Add a Render Postgres instance and set `DATABASE_URL`.
3) Add a Render Redis instance (recommended for Channels) and set `REDIS_URL`.
4) Set environment variables:
```
DJANGO_SECRET_KEY=...
DEBUG=0
ALLOWED_HOSTS=your-service.onrender.com
CSRF_TRUSTED_ORIGINS=https://your-service.onrender.com
CORS_ALLOWED_ORIGINS=https://your-frontend-domain.com
DATABASE_URL=...
REDIS_URL=...
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=...
EMAIL_PORT=587
EMAIL_HOST_USER=...
EMAIL_HOST_PASSWORD=...
EMAIL_USE_TLS=1
DEFAULT_FROM_EMAIL=no-reply@your-domain.com
```
5) Run migrations (Render Shell):
```
python manage.py migrate
```

Health check: `GET /healthz`

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
