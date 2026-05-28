from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field


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
