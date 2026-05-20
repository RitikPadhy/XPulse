# Mobile Data — iOS (HealthKit, phone-only)

Scope: data the **iPhone alone** produces. No Apple Watch, no Garmin, no Whoop — those come in a separate doc when we tackle wearables.

The iPhone has a motion coprocessor (M-series chip) that tracks activity passively whenever the phone is on the user. HealthKit is where that data lives. We read from HealthKit, normalize it, push it to the backend.

## What the phone gives us

| Data type             | HealthKit identifier                          |
| --------------------- | --------------------------------------------- |
| Steps                 | `HKQuantityTypeIdentifierStepCount`           |
| Walking + running km  | `HKQuantityTypeIdentifierDistanceWalkingRunning` |
| Flights climbed       | `HKQuantityTypeIdentifierFlightsClimbed`      |
| Walking speed         | `HKQuantityTypeIdentifierWalkingSpeed`        |
| Walking step length   | `HKQuantityTypeIdentifierWalkingStepLength`   |

That's the full phone-only menu. No heart rate, no sleep, no HRV, no workouts — those all require a wearable.

## Flow

```
   ┌─────────────────────────────┐
   │   iPhone motion coprocessor │
   │   (M-series chip, always on)│
   └──────────────┬──────────────┘
                  │ writes passively
                  ▼
   ┌─────────────────────────────┐
   │       HealthKit (iOS)       │
   │  steps · distance · stairs  │
   │  walking gait metrics       │
   └──────────────┬──────────────┘
                  │ read (with user permission)
                  ▼
   ┌─────────────────────────────┐
   │  XPulse app (Flutter)       │
   │  via `health` package       │
   │   1. permission on onboard  │
   │   2. observer on new sample │
   │   3. pull deltas since sync │
   │   4. normalize → POST       │
   └──────────────┬──────────────┘
                  │ HTTPS
                  ▼
          ┌───────────────┐
          │   FastAPI     │
          └───────────────┘
```

## How

1. **Add the capability.** Xcode → Runner target → Signing & Capabilities → +Capability → HealthKit.
2. **Declare intent.** Add `NSHealthShareUsageDescription` to `ios/Runner/Info.plist`.
3. **Request permission once.** On first launch, ask for steps, distance, flights climbed, gait metrics.
4. **Subscribe to changes.** Register an `HKObserverQuery` with background delivery so HealthKit wakes us when new samples land.
5. **Pull deltas, not snapshots.** Track the last sync timestamp per data type; query only samples newer than that.
6. **Normalize before sending.** Flatten HealthKit's sample shapes into the schema the backend expects, then `POST /sync/biometrics`.

All of step 3–5 goes through the [`health`](https://pub.dev/packages/health) Flutter package — no native Swift code needed.

## What this means for gameplay

With phone-only data, only step-based quests work (`q_steps_baseline`, `q_long_walk`). The HR-zone, HRV, sleep, and calorie quests are dead until we add wearable support. Plan for the degraded experience now; design the upgrade prompt for when a user is ready to connect a watch.