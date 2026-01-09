# Smart Trip Planner (Phase 1)

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
