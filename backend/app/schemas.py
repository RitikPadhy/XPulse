from datetime import date, datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class HealthSampleIn(BaseModel):
    """Incoming sample from the iOS app.

    Accepts both the legacy shape (`value`, `source`, `device`) and the
    full HealthKit-aware shape (`value_quantity`, `value_category`, workout
    fields, full provenance, etc.). Field aliases let either name flow in.
    """

    model_config = ConfigDict(populate_by_name=True)

    type: str = Field(description="HealthKit type identifier, e.g. HKQuantityTypeIdentifierStepCount")
    start_date: datetime
    end_date: datetime

    healthkit_uuid: str | None = None
    sample_category: str = "quantity"

    # HKQuantitySample — `value` is the legacy field name from the iOS app
    value_quantity: float | None = Field(default=None, alias="value")
    unit: str | None = None

    # HKCategorySample
    value_category: int | None = None

    # HKWorkout
    workout_activity_type: int | None = None
    workout_duration_seconds: float | None = None
    workout_total_distance_m: float | None = None
    workout_total_energy_kcal: float | None = None
    workout_total_flights: int | None = None
    workout_total_swim_strokes: int | None = None

    # Provenance — `source` / `device` are the legacy field names
    source_name: str | None = Field(default=None, alias="source")
    source_bundle_id: str | None = None
    source_version: str | None = None
    source_operating_system: str | None = None
    device_name: str | None = Field(default=None, alias="device")
    device_model: str | None = None
    device_manufacturer: str | None = None
    device_hardware_version: str | None = None
    device_software_version: str | None = None
    device_local_identifier: str | None = None

    was_user_entered: bool = False
    time_zone: str | None = None

    metadata: dict[str, Any] | None = None


class HealthSampleOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    type: str
    start_date: datetime
    end_date: datetime
    value_quantity: float | None = None
    unit: str | None = None
    value_category: int | None = None
    source_name: str | None = None
    device_name: str | None = None


class IngestRequest(BaseModel):
    samples: list[HealthSampleIn]


class IngestResponse(BaseModel):
    received: int
    inserted: int
    duplicates: int


class HealthStatus(BaseModel):
    status: str
    env: str


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
