from fastapi import Depends, Header, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.config import Settings, get_settings
from app.db import get_db
from app.models import User


def get_current_user(
    authorization: str | None = Header(default=None),
    settings: Settings = Depends(get_settings),
    db: Session = Depends(get_db),
) -> User:
    expected = f"Bearer {settings.api_token}"
    if not authorization or authorization != expected:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="invalid api token",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user = db.scalars(select(User).order_by(User.id).limit(1)).first()
    if user is None:
        user = User(name="default")
        db.add(user)
        db.commit()
        db.refresh(user)
    return user
