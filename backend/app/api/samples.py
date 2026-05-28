from datetime import datetime

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.orm import Session

from app.auth import get_current_user
from app.db import get_db
from app.models import HealthSample, User
from app.schemas import HealthSampleOut, IngestRequest, IngestResponse

router = APIRouter(prefix="/v1/samples", tags=["samples"])


@router.post("", response_model=IngestResponse)
def ingest(
    payload: IngestRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> IngestResponse:
    received = len(payload.samples)
    if received == 0:
        return IngestResponse(received=0, inserted=0, duplicates=0)

    rows = [
        {"user_id": user.id, **sample.model_dump()} for sample in payload.samples
    ]
    stmt = (
        pg_insert(HealthSample)
        .values(rows)
        .on_conflict_do_nothing(
            index_elements=["user_id", "type", "start_date", "end_date"]
        )
        .returning(HealthSample.id)
    )
    inserted = len(db.execute(stmt).scalars().all())
    db.commit()

    return IngestResponse(
        received=received,
        inserted=inserted,
        duplicates=received - inserted,
    )


@router.get("", response_model=list[HealthSampleOut])
def list_samples(
    type: str | None = Query(default=None, description="Filter by HealthKit type identifier"),
    since: datetime | None = Query(default=None),
    limit: int = Query(default=200, le=1000),
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[HealthSample]:
    stmt = select(HealthSample).where(HealthSample.user_id == user.id)
    if type:
        stmt = stmt.where(HealthSample.type == type)
    if since:
        stmt = stmt.where(HealthSample.start_date >= since)
    stmt = stmt.order_by(HealthSample.start_date.desc()).limit(limit)
    return list(db.scalars(stmt).all())
