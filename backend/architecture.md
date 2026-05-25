# Architecture

## Data flow

```
iPhone sensors ──┐
Apple Watch ─────┤
3rd-party apps ──┼──► Health app (HealthKit store) ──► XPulse iOS app ──► Backend (Oracle Free Tier)
Connected devs ──┤
Manual entries ──┘
```

- **iPhone-only path is sufficient.** The iPhone's motion coprocessor writes steps, distance, flights climbed, walking metrics, etc. directly into the Health app's HealthKit store. An Apple Watch is *not* required.
- **HealthKit** is the read/write API over the Health app's database. Our app calls `HKHealthStore` + `HKQuery` after the user grants per-type permissions.
- HealthKit returns a **unified view** across all sources. Filter by `HKSource` / `HKDevice` only if origin matters.

## Components

- **iOS app (Flutter)** — requests HealthKit permissions, queries data, syncs to backend.
- **Backend (Oracle Cloud Free Tier)** — receives, stores, and serves aggregated data.
  - Compute: Always Free ARM Ampere VM
  - DB: Autonomous Database (Always Free) or Postgres on the VM
  - Auth + HTTPS in front of the API

## Sync model

- App pulls from HealthKit on launch + periodic background refresh.
- Delta-sync to backend (anchored queries via `HKAnchoredObjectQuery`) — only new samples since last anchor.
