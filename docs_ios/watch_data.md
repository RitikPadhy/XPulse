# Watch Data — iOS

Scope: how we ingest data from a user's wearable. Two paths depending on whether the watch funnels through HealthKit.

## Path A — User toggles HealthKit on (happy path)

Apple Watch is automatic. Garmin / Whoop / Oura / Polar require the user to open the vendor's own app and flip the Apple Health switch. Once on, we read everything through HealthKit — one code path for all watches.

```
┌─────────────┐   ┌─────────┐   ┌─────────┐   ┌────────┐
│Apple Watch  │   │ Garmin  │   │  Whoop  │   │  Oura  │
└──────┬──────┘   └────┬────┘   └────┬────┘   └────┬───┘
       │ auto          │ toggle      │ toggle      │ toggle
       ▼               ▼             ▼             ▼
       ┌────────────────────────────────────────────┐
       │              HealthKit (iOS)               │
       │  HR · HRV · sleep · workouts · kcal · ...  │
       └────────────────────┬───────────────────────┘
                            │ read
                            ▼
                  ┌────────────────────┐
                  │   XPulse app       │
                  └─────────┬──────────┘
                            ▼
                       ┌─────────┐
                       │ FastAPI │
                       └─────────┘
```

Same `health` Flutter package, same observer query, same delta-sync logic as `mobile_data.md`. Just more data types in the permission ask.

## Path B — User won't toggle HealthKit (fallback)

If the user refuses (or forgets) the vendor toggle, HealthKit returns empty arrays for HR/HRV/sleep and we can't tell why. The escape hatch is **direct OAuth against the vendor's own cloud** — bypass HealthKit entirely, pull from the vendor's servers.

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   Garmin     │    │    Whoop     │    │    Oura      │
│   Cloud      │    │    Cloud     │    │    Cloud     │
└──────┬───────┘    └──────┬───────┘    └──────┬───────┘
       │ webhook           │ webhook           │ webhook
       │ + OAuth pull      │ + OAuth pull      │ + OAuth pull
       └──────────┬────────┴──────────┬────────┘
                  ▼                   ▼
                  ┌────────────────────────────┐
                  │       FastAPI backend      │
                  │  stores tokens, ingests    │
                  │  vendor payloads, normalizes│
                  └─────────────┬──────────────┘
                                │ same schema as Path A
                                ▼
                       ┌────────────────────┐
                       │     XPulse app     │
                       └────────────────────┘
```

Notice the difference: in Path A the **app** reads from HealthKit on-device. In Path B the **backend** reads from the vendor cloud server-to-server, and the app just queries our own backend. The user does one OAuth flow inside XPulse during onboarding; after that it's automatic.

## How (Path B)

1. **In-app OAuth.** "Connect Garmin" button → opens vendor login in a webview → user authorizes XPulse → vendor redirects back with a code.
2. **Backend exchanges code for tokens.** Stores refresh + access tokens per user, encrypted.
3. **Subscribe to webhooks.** Vendor pushes new activity / sleep / HR data to our endpoint as soon as the watch syncs to their cloud.
4. **Normalize.** Vendor payloads → same internal schema as the HealthKit-sourced data. Quests don't know or care which path the data came from.

## Vendor-specific access reality

| Vendor | Self-serve API? | Webhooks? | Notes |
| ------ | --------------- | --------- | ----- |
| Whoop  | Yes             | Yes       | Build first — easiest |
| Oura   | Yes             | Yes (v2)  | Build second |
| Polar  | Yes (AccessLink)| Yes       | Smaller user base, lower priority |
| Fitbit | Yes             | Yes       | Only path for Fitbit users (no Apple Health bridge) |
| Garmin | **No — partner approval required, weeks of review** | Yes | Apply early, build others while waiting |

## When we actually build Path B

Not for v1. TestFlight is ~10 friends — if one has a Garmin and won't toggle, ask them in person. Build Path B when:

- A real user complains their toggle is on and data still isn't flowing (HealthKit subset isn't enough), or
- Multiple users sign up with the same non-toggling vendor (signal: the toggle UX is the bottleneck for that vendor).

Start with **Whoop direct** (self-serve, easiest API), then **Oura**, then apply for **Garmin** while building those.
