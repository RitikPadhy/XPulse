from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from ..db import get_session
from ..models import User
from ..schemas import UserCreate, UserOut

router = APIRouter(prefix="/users", tags=["users"])


@router.post("", response_model=UserOut, status_code=status.HTTP_201_CREATED)
async def create_user(
    payload: UserCreate,
    session: AsyncSession = Depends(get_session),
) -> User:
    user = User(display_name=payload.display_name, avatar=payload.avatar)
    session.add(user)
    await session.commit()
    await session.refresh(user)
    return user


@router.get("/{user_id}", response_model=UserOut)
async def get_user(
    user_id: str,
    session: AsyncSession = Depends(get_session),
) -> User:
    user = await session.get(User, user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="user not found")
    return user
