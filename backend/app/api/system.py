from fastapi import APIRouter, Depends

from app.config import Settings, get_settings
from app.schemas import HealthStatus

router = APIRouter(tags=["system"])


@router.get("/health", response_model=HealthStatus)
def health(settings: Settings = Depends(get_settings)) -> HealthStatus:
    return HealthStatus(status="ok", env=settings.env)
