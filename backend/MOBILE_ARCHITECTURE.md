# Architecture — Real-Time Biometrics → XP

How HealthKit data flows into the UI so the XP bar (and anything else biometric-driven) updates as the user moves.

## Reality of "real-time" on iOS

HealthKit doesn't push individual heartbeats. Samples land at the platform's cadence:

- **Steps / active energy:** tick every few seconds while moving.
- **Heart rate (Watch):** every few seconds during workouts, sparser at rest.
- **Heart rate (phone-only):** none, unless a paired sensor exists.

So "real-time" in this app means: **foreground poll** + **observer query when backgrounded**. The XP bar updates as fast as HealthKit has new data, which is fast enough to feel live for activity-driven XP.

## Module layout

Slots into the existing `core/` → `ui/` separation. Nothing in `ui/` changes.

```
lib/core/
├── health/
│   ├── health_service.dart          # thin wrapper over `health` pkg: auth + queries
│   └── biometrics_repository.dart   # Stream<BiometricsSnapshot> — single source of truth
├── xp/
│   └── xp_engine.dart               # pure fn: (biometrics, baselines, quests) → xp
├── models/
│   └── biometrics_snapshot.dart     # steps, activeEnergy, hr, takenAt
└── app_state.dart                   # existing; subscribes to repo stream
```

## Data flow

```
HealthKit → HealthService → BiometricsRepository (Stream)
                                    │
                                    ▼
                              XpEngine (pure)
                                    │
                                    ▼
                              AppState.notifyListeners()
                                    │
                                    ▼
                       XPBar rebuilds (already wired via AppStateScope)
```

The UI layer doesn't know HealthKit exists. Screens still read `AppStateScope.of(context)`; the XP bar already rebuilds on `notifyListeners()`. The whole biometrics pipeline is invisible to skins.

## How the repository stays live

- **Foregrounded:** one-shot read of today's totals on open, then poll every ~5s (configurable). HealthKit reads are local SQLite — cheap.
- **Backgrounded:** `HKObserverQuery` + background delivery for HR/HRV. Wakes the app, repo re-reads, snapshot flows through `XpEngine`. *Phase 2 — skipped initially.*
- **Lifecycle aware:** repo listens to `AppLifecycleState` and pauses polling when not visible to save battery.

## Why a Stream, not polling inside AppState

- `AppState` stays UI-state-only (active quests, etc.); biometrics is a separate concern.
- Multiple subscribers can fan out: XP bar, a future live-HR widget, a debug overlay.
- Swappable: a `FakeBiometricsRepository` in dev emits canned data every second, so the whole UI can be exercised without a real device (the iOS Simulator returns empty HealthKit data — see [data_collection.md](data_collection.md)).

## XpEngine is pure on purpose

`(snapshot, baselines, quests) → XpState`. Same inputs, same outputs. Two consequences:

- **Replayable:** feed a day's HealthKit samples through it and verify the XP bar lands exactly where it should.
- **Safe to ship via Shorebird:** balance changes (XP curves, crit thresholds) are Dart-only, so they push OTA without a store submission.

## Tradeoff to call out

Polling every 5s is fine for steps, but heart rate samples arrive at HealthKit's cadence regardless of poll frequency — the XP bar will *feel* live for walking, less live for HR-driven XP. If HR-real-time matters, skip polling and use anchored observer queries from day one (more code, more edge cases).

**Decision:** start with polling. Add observers only if the lag is noticeable in practice.

## Phase ordering

1. `BiometricsSnapshot` model + `HealthService` (auth + one-shot read).
2. `BiometricsRepository` with foreground polling + `FakeBiometricsRepository` for dev.
3. `XpEngine` stub returning current behavior, then wire real logic.
4. `AppState` subscribes; XP bar starts moving on real steps.
5. Background delivery + observer queries.