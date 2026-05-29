from datetime import date, datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class HealthStatus(BaseModel):
    status: str
    env: str


class SignupRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)
    display_name: str = Field(min_length=1, max_length=255)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class AuthResponse(BaseModel):
    token: str
    user_id: int


class QuestSyncRequest(BaseModel):
    """Two on-device summaries, keyed by HealthKit type name. Nothing raw is
    stored — HealthKit remains the source of truth.

    - `baselines`: 7-day median daily total per metric → quest targets.
    - `totals`: today's summed total per metric → progress / proportional XP.
    """

    baselines: dict[str, float] = {}
    totals: dict[str, float] = {}


class UserDetailsOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    email: str | None = None
    phone: str | None = None
    display_name: str | None = None
    date_of_birth: date | None = None
    biological_sex: str | None = None
    height_cm: float | None = None
    weight_kg: float | None = None
    timezone: str | None = None
    locale: str | None = None
    country: str | None = None
    avatar_key: str | None = None
    bio: str | None = None
    onboarded_at: datetime | None = None
    last_active_at: datetime | None = None
    ios_app_version: str | None = None
    ios_device_model: str | None = None
    created_at: datetime
    updated_at: datetime


class UserDetailsUpdate(BaseModel):
    """All fields optional — PATCH semantics. Unset fields are not touched."""

    email: EmailStr | None = None
    phone: str | None = None
    display_name: str | None = None
    date_of_birth: date | None = None
    biological_sex: str | None = Field(
        default=None,
        pattern="^(male|female|other|not_set)$",
    )
    height_cm: float | None = Field(default=None, ge=0, le=300)
    weight_kg: float | None = Field(default=None, ge=0, le=500)
    timezone: str | None = None
    locale: str | None = None
    country: str | None = Field(default=None, min_length=2, max_length=2)
    avatar_key: str | None = None
    bio: str | None = None
    ios_app_version: str | None = None
    ios_device_model: str | None = None


class MeOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    role: str
    created_at: datetime
    details: UserDetailsOut | None = None


class FriendSummary(BaseModel):
    """One row in the friends leaderboard."""

    id: int
    display_name: str
    avatar_key: str | None = None
    country: str | None = None
    daily_xp: int
    total_xp: int
    rank: int


class DailyXp(BaseModel):
    day: date
    xp: int


class UserPublicOut(BaseModel):
    """A friend's profile as seen by anyone in the leaderboard."""

    id: int
    display_name: str
    avatar_key: str | None = None
    country: str | None = None
    bio: str | None = None
    joined_at: datetime
    daily_xp: int
    total_xp: int
    rank: int | None = None
    last_7_days: list[DailyXp] = []


class SnapshotOut(BaseModel):
    """One-shot payload for the three main pages.

    `me`, `friends`, and `quests` come from real DB data. `today` is a
    server-computed default (XP earned today, daily goal, etc.) — the
    metric breakdown will fill in as we wire the gamification side.
    """

    me: MeOut
    friends: list[FriendSummary]
    today: dict[str, Any] | None = None
    quests: dict[str, Any] | None = None
