"""Quest engine: baselines → recommendation → progress → XP grant.

How a user gets quests:

1. On `GET /v1/me/snapshot`, we look for a non-expired pool of size 10
   (4 active + 6 available). If missing, we generate a fresh pool.
2. Targets are computed from the user's 7-day baseline per metric:
   `target = baseline_median × stretch_factor[tier]`
3. Active slot defaults to one Medium quest per distinct metric (up to 4).
   Available slot holds the rest (Easy/Hard/Epic variants + extra metrics).
4. Each snapshot fetch also refreshes `progress_value` for every quest by
   summing matching health samples in the quest's window. Any quest whose
   progress hits its target is auto-completed and the XP is credited to
   `user_xp_daily` for today.

Quests stay around until `expires_at`. For daily quests that's midnight
UTC of the day after assignment.
"""

from datetime import date, datetime, timedelta, timezone

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models import HealthSample, QuestCatalog, UserQuest, UserXpDaily

POOL_SIZE = 10
ACTIVE_SLOTS = 4


def _utc_now() -> datetime:
    return datetime.now(timezone.utc)


def _quest_window(duration: str) -> tuple[datetime, datetime]:
    """Returns (starts_at, expires_at) UTC for a freshly assigned quest."""
    now = _utc_now()
    day_start = datetime.combine(now.date(), datetime.min.time(), tzinfo=timezone.utc)
    days = {"daily": 1, "streak3": 3, "weekly": 7, "monthly": 30}.get(duration, 1)
    return day_start, day_start + timedelta(days=days)


def compute_baselines(db: Session, user_id: int) -> dict[str, float]:
    """Median daily total per metric across the last 7 days."""
    since = _utc_now() - timedelta(days=7)
    per_day = (
        select(
            HealthSample.type.label("type"),
            func.date(HealthSample.start_date).label("day"),
            func.sum(HealthSample.value_quantity).label("daily_total"),
        )
        .where(
            HealthSample.user_id == user_id,
            HealthSample.start_date >= since,
            HealthSample.value_quantity.isnot(None),
        )
        .group_by(HealthSample.type, "day")
        .subquery()
    )
    stmt = (
        select(
            per_day.c.type,
            func.percentile_cont(0.5).within_group(per_day.c.daily_total).label("median"),
        )
        .group_by(per_day.c.type)
    )
    return {
        row.type: float(row.median)
        for row in db.execute(stmt).all()
        if row.median is not None and row.median > 0
    }


def _progress_for(
    db: Session, user_id: int, metric: str, start: datetime, end: datetime
) -> float:
    total = db.scalar(
        select(func.coalesce(func.sum(HealthSample.value_quantity), 0)).where(
            HealthSample.user_id == user_id,
            HealthSample.type == metric,
            HealthSample.start_date >= start,
            HealthSample.start_date < end,
        )
    )
    return float(total or 0)


def _generate_pool(db: Session, user_id: int) -> list[UserQuest]:
    """Build a fresh 10-quest pool for the user. Persists & returns the rows."""
    baselines = compute_baselines(db, user_id)
    if not baselines:
        return []

    catalog: list[QuestCatalog] = list(
        db.scalars(select(QuestCatalog).where(QuestCatalog.is_active.is_(True))).all()
    )

    # Build candidates: only metrics where we have baseline data
    candidates: list[tuple[QuestCatalog, float]] = []
    for entry in catalog:
        baseline = baselines.get(entry.metric)
        if baseline is None:
            continue
        target = baseline * entry.stretch_factor
        candidates.append((entry, target))

    # ACTIVE: one Medium quest per distinct metric (up to 4 metrics)
    active: list[tuple[QuestCatalog, float]] = []
    used_metrics: set[str] = set()
    for entry, target in candidates:
        if entry.tier == "medium" and entry.metric not in used_metrics:
            active.append((entry, target))
            used_metrics.add(entry.metric)
            if len(active) >= ACTIVE_SLOTS:
                break

    # AVAILABLE: fill remaining slots with non-medium tiers and unused metrics
    active_ids = {id(c[0]) for c in active}
    available: list[tuple[QuestCatalog, float]] = []
    # First, Hard tier for the active metrics (lets users escalate)
    for entry, target in candidates:
        if id(entry) in active_ids:
            continue
        if entry.metric in used_metrics and entry.tier in ("hard", "epic"):
            available.append((entry, target))
            if len(available) >= POOL_SIZE - len(active):
                break
    # Then Easy for the active metrics (downshift option)
    for entry, target in candidates:
        if id(entry) in active_ids or (entry, target) in available:
            continue
        if entry.metric in used_metrics and entry.tier == "easy":
            available.append((entry, target))
            if len(available) >= POOL_SIZE - len(active):
                break
    # Then any Medium quests on unused metrics (extra variety)
    for entry, target in candidates:
        if id(entry) in active_ids or (entry, target) in available:
            continue
        if entry.tier == "medium" and entry.metric not in used_metrics:
            available.append((entry, target))
            if len(available) >= POOL_SIZE - len(active):
                break

    # Persist
    rows: list[UserQuest] = []
    for entry, target in active:
        s, e = _quest_window(entry.duration)
        rows.append(
            UserQuest(
                user_id=user_id, catalog_id=entry.id, slot="active",
                target_value=target, starts_at=s, expires_at=e,
            )
        )
    for entry, target in available:
        s, e = _quest_window(entry.duration)
        rows.append(
            UserQuest(
                user_id=user_id, catalog_id=entry.id, slot="available",
                target_value=target, starts_at=s, expires_at=e,
            )
        )
    db.add_all(rows)
    db.commit()
    for r in rows:
        db.refresh(r)
    return rows


def get_or_assign_pool(db: Session, user_id: int) -> list[UserQuest]:
    """Returns the user's current non-expired quest pool. Generates one if
    none exists. Also expires stale rows."""
    now = _utc_now()
    existing: list[UserQuest] = list(
        db.scalars(
            select(UserQuest)
            .where(UserQuest.user_id == user_id, UserQuest.status != "expired")
            .order_by(UserQuest.assigned_at.desc())
        ).all()
    )

    # Mark anything past its expires_at as expired (snapshot won't return them)
    fresh = []
    dirty = False
    for q in existing:
        if q.expires_at <= now and q.status != "expired":
            q.status = "expired"
            dirty = True
            continue
        if q.expires_at > now:
            fresh.append(q)
    if dirty:
        db.commit()

    if len(fresh) >= POOL_SIZE:
        return fresh

    return _generate_pool(db, user_id)


def refresh_progress(db: Session, quests: list[UserQuest]) -> int:
    """For each in-progress quest, update progress_value from health_samples.
    If progress >= target, auto-complete and credit XP to today's row.
    Returns total XP granted in this call."""
    now = _utc_now()
    today = now.date()
    total_xp = 0

    for q in quests:
        if q.status != "inProgress":
            continue
        q.progress_value = _progress_for(
            db, q.user_id, q.catalog.metric, q.starts_at, q.expires_at
        )
        if q.progress_value >= q.target_value:
            q.status = "complete"
            q.completed_at = now
            reward = q.catalog.xp_reward
            row = db.scalar(
                select(UserXpDaily).where(
                    UserXpDaily.user_id == q.user_id,
                    UserXpDaily.day == today,
                )
            )
            if row is None:
                db.add(UserXpDaily(user_id=q.user_id, day=today, xp=reward))
            else:
                row.xp = (row.xp or 0) + reward
            total_xp += reward

    db.commit()
    return total_xp


def serialize_pool(quests: list[UserQuest]) -> dict:
    """Returns the `quests` block in the shape `UserSnapshot.fromJson` parses."""
    active = [q for q in quests if q.slot == "active"]
    return {
        "activeIds": [str(q.id) for q in active],
        "pool": [
            {
                "id": str(q.id),
                "title": q.catalog.title,
                "metric": q.catalog.metric,
                "target": q.target_value,
                "current": q.progress_value,
                "xpReward": q.catalog.xp_reward,
                "status": "complete" if q.status == "complete" else "inProgress",
            }
            for q in quests
        ],
    }
