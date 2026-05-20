# Data Collection

## HealthKit (phase 1)

iPhone is the only source for now. Everything goes through Apple's **HealthKit** via the Flutter [`health`](https://pub.dev/packages/health) package — one read API that transparently picks up Apple Watch data when a Watch is paired, so the same code path scales from phone-only users to Watch users without branching.

### What we read first

Three metrics, picked because they exist on phone-only and get richer with a Watch:

- **Steps** — passive, always-on, baseline activity signal.
- **Active energy burned** — rough on phone-only, accurate with Watch.
- **Heart rate** — only present if a Watch (or compatible AirPods/3rd-party strap) is paired; gracefully empty otherwise.

### Permissions

- `NSHealthShareUsageDescription` in `ios/Runner/Info.plist` — required to read.
- HealthKit capability enabled on the Runner target in Xcode.
- Read-only for now. No writes.

### Constraints

- **Real device required.** The iOS Simulator returns empty HealthKit data.
- Permissions are per-data-type and one-way: once a user denies a type, the app cannot re-prompt — they have to flip it in Settings → Privacy → Health.
- Background delivery is opt-in per type; phase 1 reads on app open only.

### Next phases (not yet built)

- **Tracking sessions:** GPS route, pace, elevation during an explicit "start workout" flow (CoreLocation + HealthKit workout write).
- **Watch-specific:** HRV, resting HR, sleep stages, VO2 max, rings — read identically through HealthKit, surfaced in UI only when present.