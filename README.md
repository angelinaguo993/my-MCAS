# myMCAS
# An MCAS Tracker

## Running the backend

```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload
```

This starts the API at `http://127.0.0.1:8000` and creates a local SQLite
database (`mcas_tracker.db`) automatically on first run. Interactive API
docs are available at `http://127.0.0.1:8000/docs` — useful for testing
each endpoint before wiring up the Swift app.

Endpoints:
- `GET  /dashboard` — days since last episode (Flow 1)
- `POST /episodes` — submit the survey (Flow 2)
- `GET  /episodes?year=&month=` — episodes for the calendar (Flow 3)
- `GET  /episodes/{id}` — single episode detail

## Running the iOS app

Open `ios/mcastracker` in Xcode (create an Xcode project here if you
haven't already, and drag these files/folders in — see the earlier note
about using Xcode's file navigator rather than just moving files on disk).

The Simulator can reach the backend at `http://127.0.0.1:8000` with no
extra setup (that's already set in `networking/endpoints.swift`). Just
make sure the backend is running before you launch the app.

If you test on a physical device instead of the Simulator, change
`Endpoints.baseURL` to your Mac's LAN IP, e.g. `http://192.168.1.23:8000`.

## What's implemented

All three core flows end-to-end, wired to a real (if simple) database:
1. Dashboard → days since last episode → "Record Episode" button
2. Structured survey (triggers, per-system symptoms with severity, medication)
3. Calendar view of history → tap a day → episode detail

## What's intentionally left simple for now

- No authentication (single-user, matches your "no additional roles" spec)
- No weather API integration yet — add a `weather` field to the trigger
  list and a `services/weather_service.py` on the backend when ready
- No statistical insights endpoint yet — `backend/app/analysis/` is a
  good next step once you have a few weeks of real logged data to test against
