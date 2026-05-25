from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class HealthSampleIn(BaseModel):
    type: str = Field(description="HealthKit type identifier, e.g. HKQuantityTypeIdentifierStepCount")
    value: float
    unit: str
    start_date: datetime
    end_date: datetime
    source: str | None = None
    device: str | None = None


class HealthSampleOut(HealthSampleIn):
    model_config = ConfigDict(from_attributes=True)

    id: int


class IngestRequest(BaseModel):
    samples: list[HealthSampleIn]


class IngestResponse(BaseModel):
    received: int
    inserted: int
    duplicates: int


class HealthStatus(BaseModel):
    status: str
    env: str
