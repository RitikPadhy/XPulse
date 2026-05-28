import secrets

import bcrypt
from fastapi import Depends, Header, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.config import Settings, get_settings
from app.db import get_db
from app.models import User


def hash_password(plain: str) -> str:
    """Returns a bcrypt hash string ($2b$12$…) safe to store in the DB."""
    return bcrypt.hashpw(plain.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def verify_password(plain: str, hashed: str) -> bool:
    try:
        return bcrypt.checkpw(plain.encode("utf-8"), hashed.encode("utf-8"))
    except ValueError:
        return False


def generate_token() -> str:
    """Opaque per-user bearer token (~43 URL-safe chars)."""
    return secrets.token_urlsafe(32)


def get_current_user(
    authorization: str | None = Header(default=None),
    settings: Settings = Depends(get_settings),
    db: Session = Depends(get_db),
) -> User:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="missing or malformed authorization",
            headers={"WWW-Authenticate": "Bearer"},
        )
    token = authorization[len("Bearer "):]

    # 1. Per-user token lookup (the path real signups go through).
    user = db.scalar(select(User).where(User.api_token == token))
    if user is not None:
        return user

    # 2. Legacy fallback: a single global token (from XPULSE_API_TOKEN env) maps
    #    to user id=1, the admin. Keeps the existing app working while signups
    #    roll in. Drop this once the admin migrates to a real password.
    if token == settings.api_token:
        admin = db.scalar(select(User).where(User.id == 1))
        if admin is not None:
            return admin

    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="invalid token",
        headers={"WWW-Authenticate": "Bearer"},
    )
