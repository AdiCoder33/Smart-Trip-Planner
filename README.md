# Smart Trip Planner (Phase 3)

## Features
- Itinerary management with drag-and-drop reorder
- Expense splitting with per-member summaries
- Polls with voting + per-user vote tracking
- Collaborator invites via email + token acceptance
- Offline-first caching with a sync queue for itinerary and polls
- Real-time trip chat with WebSockets + encrypted payloads
- Calendar export (ICS)
- Render deployment readiness + GitHub Actions CI

## Run locally
1) Backend (Docker)
```bash
cd backend
cp .env.example .env
docker compose up --build
```

2) Flutter app
```bash
cd frontend
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

## Tests
Backend:
```bash
cd backend
pip install -e .[dev]
python -m pytest
```

If running tests on the host (not inside Docker), use a localhost DB:
```
DATABASE_URL=postgres://smart_trip_planner:smart_trip_planner@localhost:5432/smart_trip_planner
```

Frontend:
```bash
cd frontend
flutter test
```

## Lint
Backend:
```bash
cd backend
ruff check .
black .
```

Frontend:
```bash
cd frontend
flutter analyze
```

## Notes
- API docs: `http://localhost:8000/api/docs`
- iOS simulator base URL: `http://localhost:8000`
- Update `backend/.env` for local secrets and database settings.
- If using Android emulator, add `10.0.2.2` to `ALLOWED_HOSTS` in `backend/.env`.
- WebSocket URL: `ws://localhost:8000/ws/trips/<trip_id>/chat/?token=<JWT_ACCESS>`

## Sample invite email
```
Subject: You're invited to a trip

You've been invited to collaborate on a trip.

Trip: Paris Weekend
Role: editor
Token: <paste-this-token>

Use this token in the app to accept the invite.
```

## CI/CD
GitHub Actions workflows:
- Backend: lint + tests + docker build + Render deploy hook
- Flutter: analyze + tests + release APK build

Required GitHub Secrets:
- `RENDER_DEPLOY_HOOK` (Render deploy hook URL for backend)
