from datetime import datetime, timezone

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth import get_current_user
from app.db import get_db
from app.models import User, UserDetail
from app.schemas import MeOut, UserDetailsOut, UserDetailsUpdate

router = APIRouter(prefix="/v1/me", tags=["me"])


@router.get("", response_model=MeOut)
def get_me(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> User:
    """Return the authenticated user + profile details (creates an empty
    details row if one doesn't exist yet, so the iOS app can always count
    on a non-null object)."""
    if user.details is None:
        user.details = UserDetail(user_id=user.id)
        db.commit()
        db.refresh(user)
    # Touch last_active_at on every /me hit — cheap heartbeat.
    user.details.last_active_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(user)
    return user


@router.get("/details", response_model=UserDetailsOut)
def get_details(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> UserDetail:
    if user.details is None:
        user.details = UserDetail(user_id=user.id)
        db.commit()
        db.refresh(user)
    return user.details


@router.patch("/details", response_model=UserDetailsOut)
def update_details(
    payload: UserDetailsUpdate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> UserDetail:
    if user.details is None:
        user.details = UserDetail(user_id=user.id)

    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(user.details, field, value)

    db.commit()
    db.refresh(user.details)
    return user.details
