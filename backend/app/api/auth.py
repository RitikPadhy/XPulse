"""Signup + login. Both return an opaque bearer token the client stores in
secure storage and sends on every subsequent request."""

import re

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.auth import generate_token, hash_password, verify_password
from app.db import get_db
from app.models import User, UserDetail
from app.schemas import AuthResponse, LoginRequest, SignupRequest

router = APIRouter(prefix="/v1/auth", tags=["auth"])


def _handle_from_display_name(display_name: str) -> str:
    """Derives a short URL-ish handle from the display name. Not enforced as
    unique here — `users.name` doesn't need to be."""
    cleaned = re.sub(r"[^a-z0-9_]+", "_", display_name.lower()).strip("_")
    return cleaned[:32] or "user"


@router.post("/signup", response_model=AuthResponse, status_code=201)
def signup(payload: SignupRequest, db: Session = Depends(get_db)) -> AuthResponse:
    # Email uniqueness check (lives in user_details, not users)
    existing = db.scalar(
        select(UserDetail).where(UserDetail.email == payload.email)
    )
    if existing is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="email already registered",
        )

    token = generate_token()
    user = User(
        name=_handle_from_display_name(payload.display_name),
        role="REGULAR",
        password_hash=hash_password(payload.password),
        api_token=token,
    )
    db.add(user)
    db.flush()  # populate user.id

    db.add(UserDetail(
        user_id=user.id,
        email=payload.email,
        display_name=payload.display_name,
    ))
    db.commit()

    return AuthResponse(token=token, user_id=user.id)


@router.post("/login", response_model=AuthResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)) -> AuthResponse:
    detail = db.scalar(
        select(UserDetail).where(UserDetail.email == payload.email)
    )
    if detail is None:
        raise HTTPException(401, "invalid credentials")

    user = detail.user
    if user.password_hash is None or not verify_password(
        payload.password, user.password_hash
    ):
        raise HTTPException(401, "invalid credentials")

    # First successful password login on an admin (or other legacy user) sets
    # them a real per-user token so they no longer need the global one.
    if user.api_token is None:
        user.api_token = generate_token()
        db.commit()

    return AuthResponse(token=user.api_token, user_id=user.id)
