# Backend Architecture

Pairs with the app's [ARCHITECTURE.md](../app/ARCHITECTURE.md), which covers the on-device HealthKit → XP pipeline. This doc is the server side: what it owns, what it deliberately doesn't, and the deferred decisions.

## What the backend owns

```
Backend responsibilities
├── Auth                    # Sign in with Apple — verify identity token, mint session
├── Biometrics ingestion    # POST samples from app → store + recompute today
├── Baselines               # Rolling 7/30-day averages — daily job
├── Quests                  # Server-validated completion (anti-cheat later)
├── Dojo / clans            # Membership, weekly boss aggregation
├── Leaderboard             # Trophy totals, sortable, cached
└── Push (APNs)             # Chest unlocks, boss timers, clan events
```

The XP bar in the app is **local** (HealthKit → `XpEngine` → UI, no network round-trip). The backend only enters the picture for **shared state**: leaderboard, boss progress, friend activity, cross-device sync.

## Stack

| layer | choice | why |
| --- | --- | --- |
| framework | FastAPI + Pydantic v2 | Pydantic models map 1:1 to the Dart `UserSnapshot`/`Quest`/`Clan` shapes — contract stays tight |
| ORM | SQLAlchemy 2.0 async | typed, async engine, identical code for SQLite (dev) and Postgres (prod) |
| dev DB | SQLite via `aiosqlite` | zero-setup, file-on-disk |
| prod DB | Postgres via `asyncpg` | one DB, no TimescaleDB until scale demands it |
| auth | Sign in with Apple | iOS-only, free, no password UI to design |
| deploy | Fly.io or Railway (TBD) | one container, one Postgres, ~$5–10/mo |

## Why not Alembic yet

Schemas will churn over the next few weeks. Running `Base.metadata.create_all` on startup is fine while there are no real users — wipe `xpulse.db` and restart. When the first real user data lands, add Alembic and stamp the initial revision against the current schema.

## Realtime strategy

Same approach as the on-device side: **start simple, escalate only when lag is felt.**

- **Phase 1:** app polls `/leaderboard`, `/dojo/boss`, `/me/feed` every 30–60s while foregrounded.
- **Phase 2:** WebSocket channel per dojo for boss progress + activity feed. FastAPI supports this natively; no framework change.

## Background jobs (deferred)

Daily baseline recomputation, chest unlock timers, weekly boss reset — these need a scheduler. Choices when the time comes:

- **APScheduler** — in-process, simplest, runs alongside the API. Fine at TestFlight scale.
- **arq** — Redis-backed, separate worker process. Reach for this when jobs get heavier or the API needs to stay snappy.

Not Celery. Too much ceremony for this size.

## What this scaffold deliberately doesn't include

- Auth / Sign in with Apple verification (placeholder field on `User`).
- Migrations.
- APNs push.
- Tests.
- Logging / observability beyond uvicorn's defaults.

Each gets added when the feature it supports gets built. No upfront framework taxes.

## When to add the backend to the app

The Flutter app stays local-first until the first social feature ships. The trigger to wire a client is **leaderboard, clan boss, or friend XP comparison** — until then, this backend can sit idle and we keep iterating the single-player loop on TestFlight without an ops burden.
