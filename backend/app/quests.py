"""Quest engine: on-device baseline → 12-quest pool → 4 active = 1000 XP →
proportional progress → daily/total XP.

Day model (per user, in their LOCAL timezone, evaluated server-side so the
phone clock can't be used to cheat):

  - local midnight → the day's pool of 12 is generated; selection unlocked.
  - local noon     → the 4 active quests AUTO-LOCK; no more swaps until reset.
  - quest window   = the user's full local day (midnight → midnight), stored UTC.

Baselines are computed on-device from the last 7 days of HealthKit data and
sent to the server as a per-metric summary — we never store the raw history.

XP:
  - Each catalog tier carries a difficulty weight (`xp_reward`). The 4 ACTIVE
    quests are normalized so their weights sum to exactly DAILY_XP_BUDGET
    (1000) — harder quest → bigger slice (fair).
  - Daily XP earned = Σ over active quests of  min(progress/target, 1) × xp,
    i.e. proportional to how full each bar is. Capped at 1000.
  - total XP = Σ of every day's earned (user_xp_daily).
"""

from __future__ import annotations

from datetime import datetime, timedelta, timezone
from zoneinfo import ZoneInfo

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models import QuestCatalog, User, UserQuest, UserXpDaily

POOL_SIZE = 12
ACTIVE_SLOTS = 4
DAILY_XP_BUDGET = 1000
LOCK_HOUR = 12  # local noon


def _utc_now() -> datetime:
    return datetime.now(timezone.utc)


# ---------------------------------------------------------------- timezone / day

def _user_tz(user: User) -> ZoneInfo:
    name = (user.details.timezone if user.details else None) or "UTC"
    try:
        return ZoneInfo(name)
    except Exception:
        return ZoneInfo("UTC")


def day_bounds(tz: ZoneInfo) -> tuple[datetime, datetime, datetime]:
    """(start_utc, end_utc, lock_utc) for the user's current local day."""
    local = datetime.now(tz)
    midnight = local.replace(hour=0, minute=0, second=0, microsecond=0)
    start = midnight.astimezone(timezone.utc)
    end = (midnight + timedelta(days=1)).astimezone(timezone.utc)
    lock = midnight.replace(hour=LOCK_HOUR).astimezone(timezone.utc)
    return start, end, lock


def is_locked(user: User) -> bool:
    """True once the user's local time is at/past noon — active set is frozen."""
    return datetime.now(_user_tz(user)).hour >= LOCK_HOUR


# ---------------------------------------------------------------- fair XP split

def active_xp_map(active_quests: list[UserQuest]) -> dict[int, int]:
    """quest.id → XP, where the active set sums to exactly DAILY_XP_BUDGET.

    Each quest's slice is proportional to its catalog difficulty weight
    (`xp_reward`), so harder quests are worth more. Rounding drift is folded
    into the first quest so the total is always exactly 1000.
    """
    if not active_quests:
        return {}
    weights = {q.id: max(int(q.catalog.xp_reward), 1) for q in active_quests}
    total = sum(weights.values()) or 1
    xp = {qid: round(DAILY_XP_BUDGET * w / total) for qid, w in weights.items()}
    drift = DAILY_XP_BUDGET - sum(xp.values())
    if drift:
        first = next(iter(xp))
        xp[first] += drift
    return xp


# ---------------------------------------------------------------- generation

def _candidates(
    db: Session, baselines: dict[str, float]
) -> list[tuple[QuestCatalog, float]]:
    catalog = list(
        db.scalars(select(QuestCatalog).where(QuestCatalog.is_active.is_(True))).all()
    )
    out: list[tuple[QuestCatalog, float]] = []
    for entry in catalog:
        baseline = baselines.get(entry.metric)
        if baseline is None or baseline <= 0:
            continue
        out.append((entry, baseline * entry.stretch_factor))
    return out


def _generate_pool(
    db: Session, user: User, baselines: dict[str, float]
) -> list[UserQuest]:
    """Build a fresh 12-quest pool (4 active + 8 available) for the user's day."""
    cands = _candidates(db, baselines)
    if not cands:
        return []
    start, end, _ = day_bounds(_user_tz(user))

    # ACTIVE: one Medium quest per distinct metric (up to 4).
    chosen: list[tuple[QuestCatalog, float, str]] = []
    used: set[str] = set()
    for entry, target in cands:
        if entry.tier == "medium" and entry.metric not in used:
            chosen.append((entry, target, "active"))
            used.add(entry.metric)
            if len(chosen) >= ACTIVE_SLOTS:
                break
    # Backfill active with any tier on unused metrics if we lack 4 mediums.
    if len(chosen) < ACTIVE_SLOTS:
        for entry, target in cands:
            if entry.metric not in used:
                chosen.append((entry, target, "active"))
                used.add(entry.metric)
                if len(chosen) >= ACTIVE_SLOTS:
                    break

    chosen_ids = {id(e) for e, _, _ in chosen}
    # AVAILABLE: fill the rest of the pool with the remaining variants.
    for entry, target in cands:
        if len(chosen) >= POOL_SIZE:
            break
        if id(entry) in chosen_ids:
            continue
        chosen.append((entry, target, "available"))
        chosen_ids.add(id(entry))

    rows = [
        UserQuest(
            user_id=user.id,
            catalog_id=entry.id,
            slot=slot,
            target_value=target,
            starts_at=start,
            expires_at=end,
        )
        for entry, target, slot in chosen
    ]
    db.add_all(rows)
    db.commit()
    for r in rows:
        db.refresh(r)
    return rows


def get_or_assign_pool(
    db: Session, user: User, baselines: dict[str, float] | None = None
) -> list[UserQuest]:
    """Return the user's current (non-expired) pool. Expire stale rows. Only
    generate a new pool when there is none AND a fresh baseline was supplied
    (i.e. the app just sent its 7-day summary)."""
    now = _utc_now()
    existing = list(
        db.scalars(
            select(UserQuest)
            .where(UserQuest.user_id == user.id, UserQuest.status != "expired")
            .order_by(UserQuest.assigned_at.desc())
        ).all()
    )

    dirty = False
    fresh: list[UserQuest] = []
    for q in existing:
        if q.expires_at <= now and q.status != "expired":
            q.status = "expired"
            dirty = True
            continue
        if q.expires_at > now:
            fresh.append(q)
    if dirty:
        db.commit()

    if fresh:
        return fresh
    if baselines:
        return _generate_pool(db, user, baselines)
    return []


# ---------------------------------------------------------------- progress → XP

def today_earned(db: Session, user: User) -> int:
    """The XP already banked for the user's current day (read-only)."""
    row = db.scalar(
        select(UserXpDaily.xp).where(
            UserXpDaily.user_id == user.id, UserXpDaily.day == _utc_now().date()
        )
    )
    return int(row or 0)


def refresh_progress(
    db: Session, user: User, quests: list[UserQuest], totals: dict[str, float]
) -> int:
    """Update each quest's progress from the app-sent per-metric daily totals
    (no raw samples stored — HealthKit is the source of truth), then set
    today's XP to the PROPORTIONAL sum across the 4 active quests.

    `totals` maps metric → today's summed value. Returns earned XP.
    """
    now = _utc_now()
    day = now.date()
    active = [q for q in quests if q.slot == "active"]
    xpmap = active_xp_map(active)

    earned = 0.0
    for q in quests:
        if q.status == "expired":
            continue
        total = totals.get(q.catalog.metric)
        if total is not None:
            q.progress_value = float(total)
        frac = 0.0 if q.target_value <= 0 else min(q.progress_value / q.target_value, 1.0)
        if q.slot == "active":
            earned += frac * xpmap.get(q.id, 0)
            if frac >= 1.0:
                if q.status != "complete":
                    q.status = "complete"
                    q.completed_at = now
            else:
                q.status = "inProgress"

    earned_int = round(earned)
    row = db.scalar(
        select(UserXpDaily).where(
            UserXpDaily.user_id == user.id, UserXpDaily.day == day
        )
    )
    if row is None:
        db.add(UserXpDaily(user_id=user.id, day=day, xp=earned_int))
    else:
        # Overwrite — proportional XP is recomputed from cumulative progress
        # each call, not incremented.
        row.xp = earned_int
    db.commit()
    return earned_int


# ---------------------------------------------------------------- serialization

def serialize_pool(user: User, quests: list[UserQuest]) -> dict:
    """The `quests` block in the shape `UserSnapshot.fromJson` parses, plus the
    lock state (server-authoritative) so the app can freeze the UI."""
    active = [q for q in quests if q.slot == "active"]
    xpmap = active_xp_map(active)
    _, _, lock_utc = day_bounds(_user_tz(user))

    pool = []
    for q in quests:
        is_active = q.slot == "active"
        pool.append(
            {
                "id": str(q.id),
                "title": q.catalog.title,
                "metric": q.catalog.metric,
                # Rounded to 1 decimal for display; full precision is kept
                # internally for XP math.
                "target": round(q.target_value, 1),
                "current": round(q.progress_value, 1),
                # Active quests show their normalized 1000-budget slice;
                # available quests show their indicative difficulty value.
                "xpReward": xpmap[q.id] if is_active else int(q.catalog.xp_reward),
                "status": "complete" if q.status == "complete" else "inProgress",
            }
        )

    return {
        "activeIds": [str(q.id) for q in active],
        "pool": pool,
        "locked": is_locked(user),
        "lockAtUtc": lock_utc.isoformat(),
    }


# ---------------------------------------------------------------- catalog seed

# tier → (stretch factor vs baseline, difficulty weight used to split 1000 XP)
_TIERS = {
    "easy": (0.8, 150),
    "medium": (1.0, 250),
    "hard": (1.25, 400),
    "epic": (1.5, 600),
}
# Daily-improvable "active" metrics that map cleanly to a single summed total.
# The metric string MUST match what the app sends as a sample `type`, which is
# `HealthDataType.<X>.name` from the `health` package (e.g. "STEPS").
_METRICS = [
    ("STEPS", "Steps"),
    ("DISTANCE_WALKING_RUNNING", "Distance"),
    ("ACTIVE_ENERGY_BURNED", "Active Energy"),
    ("EXERCISE_TIME", "Exercise Minutes"),
    ("FLIGHTS_CLIMBED", "Flights Climbed"),
]


def seed_catalog(db: Session) -> int:
    """Idempotently populate quest_catalog (metric × tier daily quests).
    Returns the number of rows inserted (0 if already seeded)."""
    if db.scalar(select(func.count()).select_from(QuestCatalog)):
        return 0
    rows = []
    for metric, label in _METRICS:
        key = metric.lower()
        for tier, (stretch, xp) in _TIERS.items():
            rows.append(
                QuestCatalog(
                    slug=f"{key}-{tier}-daily",
                    title=f"{label} — {tier.title()}",
                    metric=metric,
                    tier=tier,
                    duration="daily",
                    stretch_factor=stretch,
                    xp_reward=xp,
                    is_active=True,
                )
            )
    db.add_all(rows)
    db.commit()
    return len(rows)
