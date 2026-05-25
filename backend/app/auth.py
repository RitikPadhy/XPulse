from fastapi import Depends, Header, HTTPException, status
from sqlalchemy.orm import Session

from app.config import Settings, get_settings
from app.db import get_db
from app.models import User


def require_token(
    authorization: str | None = Header(default=None),
    settings: Settings = Depends(get_settings),
) -> str:
    """Stub bearer-token auth.

    Replace with Sign in with Apple verification — exchange the identity token
    for the Apple `sub`, persist as User.apple_user_id, return it here.
    """
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing bearer token")
    token = authorization.split(" ", 1)[1].strip()
    if token != settings.api_token:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    return token


def get_current_user(
    _: str = Depends(require_token),
    db: Session = Depends(get_db),
) -> User:
    user = db.query(User).filter_by(apple_user_id="dev-user").one_or_none()
    if user is None:
        user = User(apple_user_id="dev-user")
        db.add(user)
        db.commit()
        db.refresh(user)
    return user
