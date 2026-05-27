from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.config import Settings, get_settings
from app.db import get_db
from app.schemas import HealthStatus

router = APIRouter(tags=["system"])


@router.get("/health", response_model=HealthStatus)
def health(settings: Settings = Depends(get_settings)) -> HealthStatus:
    return HealthStatus(status="ok", env=settings.env)


@router.get("/health/db", response_model=HealthStatus)
def health_db(
    settings: Settings = Depends(get_settings),
    db: Session = Depends(get_db),
) -> HealthStatus:
    db.execute(text("SELECT 1"))
    return HealthStatus(status="ok", env=settings.env)
