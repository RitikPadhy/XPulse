# XPulse — App

The mobile app lives here. This README captures the stack decisions so we don't relitigate them.

## Framework

**Flutter.**

Picked for rendering smoothness. Flutter owns the entire rendering pipeline via Impeller, so animations, scrolling, and custom-painted UI (pixel art, glows, particle effects) stay at 60/120fps — no JS bridge, no surprise jank. Android isn't a target right now, but staying on Flutter keeps that door open later for free.

## UI Architecture (swappable skins)

The visual layer is built so the entire UI can be swapped without touching business logic.

```
lib/
├── core/              # view models, state, domain logic — no widgets
├── ui/
│   ├── contracts/     # abstract ComponentLibrary: XPBar, Chest, QuestCard, etc.
│   ├── theme/         # design tokens: colors, spacing, type, time-of-day palettes
│   └── skins/
│       └── pixel_cyberpunk/   # the current skin — implements contracts/
└── app.dart           # SkinProvider wires one skin into the tree
```

Rules:

- **Screens consume contracts, never concrete widgets.** A screen asks for `XPBar`, not a specific pixel-art implementation.
- **All visual values live in `theme/`.** No hardcoded colors or sizes in screens.
- **View models know nothing about UI.** They expose state (`xpProgress: 0.62`); rendering is the UI layer's job.

Swapping the UI = write a new skin under `ui/skins/`, flip the provider at app root, done.

## Distribution & Updates

The loop is: ship to 2 friends → get feedback → push update → repeat. To keep that loop fast, we don't want to wait on App Store review for every small change.

- **OTA updates: [Shorebird](https://shorebird.dev).** Code-push for Flutter. Lets us ship Dart changes (UI tweaks, bug fixes, balance changes) to installed devices in minutes without a store submission. Native code or new permissions still require a full rebuild.
- **First install: TestFlight.** Add testers by email, no UDID juggling.
- **Versioning:** every build gets a version + build number visible in a debug menu so feedback can be tied to a specific build.

## Scope

- **Platform:** iOS only for now (TestFlight to ~2 friends, growing to ~10).
- **Priorities:** iteration speed and feel, not scale or Android parity.
