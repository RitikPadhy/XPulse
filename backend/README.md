# XPulse — Backend

FastAPI service for biometric ingestion, dojos, leaderboards, and push. iOS-only client for now (the Flutter app in `../app`). This is the starting skeleton — health endpoint, a `User` model, and SQLite-for-dev. No business logic yet; everything social/biometric is built on top of this.

See [ARCHITECTURE.md](./ARCHITECTURE.md) for the surface area and deferred decisions.

## Run

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -e .
cp .env.example .env
uvicorn app.main:app --reload
```

Server boots on `:8000`. A SQLite file `xpulse.db` is created in the working directory on first run.

## Quick check

```bash
curl localhost:8000/healthz
# → {"status":"ok"}

curl -X POST localhost:8000/users \
  -H 'content-type: application/json' \
  -d '{"display_name":"ritik"}'
# → {"id":"...","display_name":"ritik","avatar":"ronin","arena":"Bronze","trophies":0}
```

Swagger UI: `localhost:8000/docs`.

## Config

All env vars are prefixed `XPULSE_` and read from `.env`:

| var | default | notes |
| --- | --- | --- |
| `XPULSE_ENV` | `dev` | toggles SQL echo |
| `XPULSE_DATABASE_URL` | `sqlite+aiosqlite:///./xpulse.db` | swap to `postgresql+asyncpg://...` for prod |
| `XPULSE_CORS_ORIGINS` | `*` | comma-separated |
| `XPULSE_APPLE_CLIENT_ID` | — | bundle ID, used later for Sign in with Apple token verification |

## Layout

```
app/
├── main.py            # FastAPI app, CORS, lifespan (auto-creates tables)
├── config.py          # pydantic-settings
├── db.py              # async engine + get_session dependency
├── models/            # SQLAlchemy 2.0 ORM
├── schemas/           # Pydantic request/response models
└── routers/           # one file per resource
```

## Not yet wired

- Alembic migrations (using `create_all` for now — fine while schemas churn).
- Sign in with Apple token verification (`python-jose` is installed; placeholder field on `User`).
- Background jobs (baselines, chest unlocks) — APScheduler or arq when needed.
- APNs push.
- Tests — none yet. Add when there's logic worth testing.
