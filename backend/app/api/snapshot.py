"""One snapshot endpoint that powers all three pages in the app, plus a
per-user public profile endpoint for the friend-detail screen.

`me`, `friends`, and `quests` come from real DB data. `today` is a
server-computed default for now — XP totals + an empty metric map; the
breakdown fills in as the gamification logic gets wired up.
"""

from datetime import date, datetime, timedelta, timezone
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session, joinedload

from app.auth import get_current_user
from app.db import get_db
from app.models import User, UserDetail, UserQuest, UserXpDaily
from app.quests import (
    ACTIVE_SLOTS,
    get_or_assign_pool,
    refresh_progress,
    serialize_pool,
)
from app.schemas import (
    DailyXp,
    FriendSummary,
    MeOut,
    SnapshotOut,
    UserPublicOut,
)

router = APIRouter(prefix="/v1", tags=["snapshot"])


def _today() -> date:
    return datetime.now(timezone.utc).date()


def _friend_rows(
    db: Session, viewer_id: int
) -> list[tuple[int, str, str | None, str | None, int, int]]:
    """Returns the leaderboard rows the viewer sees: every REGULAR user plus
    the viewer themselves (even if the viewer is an ADMIN). Sorted by
    total XP desc.

    Returns tuples of (id, display_name, avatar_key, country, daily_xp, total_xp).
    `display_name` falls back to `users.name` if `user_details.display_name` is null.
    """
    today = _today()
    daily = func.coalesce(
        func.sum(UserXpDaily.xp).filter(UserXpDaily.day == today), 0
    ).label("daily_xp")
    total = func.coalesce(func.sum(UserXpDaily.xp), 0).label("total_xp")

    stmt = (
        select(
            User.id,
            func.coalesce(UserDetail.display_name, User.name).label("display_name"),
            UserDetail.avatar_key,
            UserDetail.country,
            daily,
            total,
        )
        .join(UserDetail, UserDetail.user_id == User.id, isouter=True)
        .join(UserXpDaily, UserXpDaily.user_id == User.id, isouter=True)
        .where((User.role == "REGULAR") | (User.id == viewer_id))
        .group_by(User.id, UserDetail.display_name, User.name, UserDetail.avatar_key, UserDetail.country)
        .order_by(total.desc(), User.id.asc())
    )
    return [tuple(row) for row in db.execute(stmt).all()]


def _stub_today() -> dict[str, Any]:
    """Default `today` block — matches sample_user.json shape so the
    existing UserSnapshot.fromJson parser is happy."""
    return {
        "date": _today().isoformat(),
        "metrics": {},
        "xp": {
            "earned": 0,
            "dailyGoal": 1000,
            "criticalStrikes": 0,
        },
    }


def _empty_quests() -> dict[str, Any]:
    """Returned when a user has no health samples yet — nothing to compute a baseline from."""
    return {"activeIds": [], "pool": []}


@router.get("/me/snapshot", response_model=SnapshotOut)
def get_snapshot(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> SnapshotOut:
    # Make sure details row exists (mirrors the /me endpoint behaviour)
    if user.details is None:
        user.details = UserDetail(user_id=user.id)
        db.commit()
        db.refresh(user)

    # Quests: load (or generate) this user's 10-quest pool, then refresh
    # progress from the latest health samples and auto-grant XP for any
    # that crossed their target.
    pool = get_or_assign_pool(db, user.id)
    refresh_progress(db, pool)
    quests_block = serialize_pool(pool) if pool else _empty_quests()

    rows = _friend_rows(db, viewer_id=user.id)
    friends = [
        FriendSummary(
            id=row[0],
            display_name=row[1],
            avatar_key=row[2],
            country=row[3],
            daily_xp=int(row[4] or 0),
            total_xp=int(row[5] or 0),
            rank=idx + 1,
        )
        for idx, row in enumerate(rows)
    ]

    return SnapshotOut(
        me=MeOut.model_validate(user),
        friends=friends,
        today=_stub_today(),
        quests=quests_block,
    )


@router.post("/me/quests/{quest_id}/activate")
def activate_quest(
    quest_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    """Move a quest from 'available' shelf to 'active'. If the user already
    has 4 active quests, the most-recently-assigned one is pushed to
    'available' to make room (so the count stays at 4)."""
    q = db.scalar(
        select(UserQuest).where(
            UserQuest.id == quest_id,
            UserQuest.user_id == user.id,
            UserQuest.status == "inProgress",
        )
    )
    if q is None:
        raise HTTPException(status_code=404, detail="quest not found")
    if q.slot == "active":
        return {"ok": True, "noop": True}

    active = list(
        db.scalars(
            select(UserQuest)
            .where(
                UserQuest.user_id == user.id,
                UserQuest.slot == "active",
                UserQuest.status == "inProgress",
            )
            .order_by(UserQuest.assigned_at.desc())
        ).all()
    )
    if len(active) >= ACTIVE_SLOTS:
        active[0].slot = "available"

    q.slot = "active"
    db.commit()
    return {"ok": True}


@router.post("/me/quests/{quest_id}/deactivate")
def deactivate_quest(
    quest_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    q = db.scalar(
        select(UserQuest).where(
            UserQuest.id == quest_id,
            UserQuest.user_id == user.id,
            UserQuest.status == "inProgress",
        )
    )
    if q is None:
        raise HTTPException(status_code=404, detail="quest not found")
    if q.slot == "available":
        return {"ok": True, "noop": True}
    q.slot = "available"
    db.commit()
    return {"ok": True}


@router.get("/users/{user_id}", response_model=UserPublicOut)
def get_user_public(
    user_id: int,
    viewer: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> UserPublicOut:
    target = db.scalar(
        select(User)
        .options(joinedload(User.details))
        .where(User.id == user_id)
    )
    if target is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="user not found")

    today = _today()
    week_start = today - timedelta(days=6)

    # XP totals + today's value in one round-trip
    agg = db.execute(
        select(
            func.coalesce(func.sum(UserXpDaily.xp), 0),
            func.coalesce(
                func.sum(UserXpDaily.xp).filter(UserXpDaily.day == today), 0
            ),
        ).where(UserXpDaily.user_id == user_id)
    ).one()
    total_xp = int(agg[0] or 0)
    daily_xp = int(agg[1] or 0)

    # Last 7 days, oldest → newest, zero-filled
    rows = db.execute(
        select(UserXpDaily.day, UserXpDaily.xp)
        .where(UserXpDaily.user_id == user_id, UserXpDaily.day >= week_start)
    ).all()
    by_day = {r.day: int(r.xp) for r in rows}
    last_7 = [
        DailyXp(day=week_start + timedelta(days=i), xp=by_day.get(week_start + timedelta(days=i), 0))
        for i in range(7)
    ]

    # Rank in the viewer's leaderboard frame (REGULAR users + the viewer).
    # `null` if the target isn't visible to the viewer.
    rank: int | None = None
    ranked = _friend_rows(db, viewer_id=viewer.id)
    for idx, row in enumerate(ranked):
        if row[0] == user_id:
            rank = idx + 1
            break

    details = target.details
    display_name = (details.display_name if details and details.display_name else target.name)

    return UserPublicOut(
        id=target.id,
        display_name=display_name,
        avatar_key=details.avatar_key if details else None,
        country=details.country if details else None,
        bio=details.bio if details else None,
        joined_at=target.created_at,
        daily_xp=daily_xp,
        total_xp=total_xp,
        rank=rank,
        last_7_days=last_7,
    )
