# Frontend (Flutter)

## Run locally
```bash
cd frontend
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

For iOS simulator use `http://localhost:8000`.

## Offline sync queue
- Itinerary and polls are cached locally and render instantly when offline.
- Offline actions (create/update/reorder itinerary, create polls, vote) are queued and replayed FIFO on reconnect or pull-to-refresh.
- Pending items show a small "Pending" label until synced.
- Chat messages are cached locally and queued when offline.

## Expenses
- Add expenses and view a per-user summary (paid, owed, net).

## Calendar export
- Export itinerary as an ICS file from the itinerary tab.

## Invites
- Invite tokens are delivered via email (console backend in dev).
- Use the "Accept invite token" button in the Collaborators tab to paste a token.

## Chat
- WebSocket URL is derived from `API_BASE_URL` (http -> ws, https -> wss).
- Messages sent offline are queued and replayed on reconnect.
- Messages are encrypted using a per-trip key fetched from `/api/trips/<trip_id>/chat/key`.

## Tests
```bash
cd frontend
flutter test
```

## Lint
```bash
cd frontend
flutter analyze
```
