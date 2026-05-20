import uuid

from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column

from .base import Base, TimestampMixin


class User(Base, TimestampMixin):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    apple_subject: Mapped[str | None] = mapped_column(String(255), unique=True, nullable=True)
    display_name: Mapped[str] = mapped_column(String(64), nullable=False)
    avatar: Mapped[str] = mapped_column(String(64), nullable=False, default="ronin")
    arena: Mapped[str] = mapped_column(String(32), nullable=False, default="Bronze")
    trophies: Mapped[int] = mapped_column(default=0, nullable=False)
