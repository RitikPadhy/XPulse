from datetime import date, datetime

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    Date,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db import Base


class User(Base):
    __tablename__ = "users"
    __table_args__ = (
        CheckConstraint("role IN ('REGULAR', 'ADMIN')", name="ck_user_role"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    # 'REGULAR' for sign-ups, 'ADMIN' for hand-created test accounts
    role: Mapped[str] = mapped_column(String(16), nullable=False, default="REGULAR")
    # bcrypt hash of the user's password; null for legacy users who only have
    # the global API token.
    password_hash: Mapped[str | None] = mapped_column(String(255))
    # Per-user bearer token. Set on signup or first password login.
    api_token: Mapped[str | None] = mapped_column(String(128), unique=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    details: Mapped["UserDetail | None"] = relationship(
        back_populates="user", uselist=False, cascade="all, delete-orphan"
    )
    xp_days: Mapped[list["UserXpDaily"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
    quests: Mapped[list["UserQuest"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )


class UserDetail(Base):
    __tablename__ = "user_details"
    __table_args__ = (
        CheckConstraint(
            "biological_sex IN ('male','female','other','not_set')",
            name="ck_user_details_sex",
        ),
    )

    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    email: Mapped[str | None] = mapped_column(String(255))
    phone: Mapped[str | None] = mapped_column(String(32))
    display_name: Mapped[str | None] = mapped_column(String(255))
    date_of_birth: Mapped[date | None] = mapped_column(Date)
    biological_sex: Mapped[str | None] = mapped_column(String(16))
    height_cm: Mapped[float | None] = mapped_column(Float)
    weight_kg: Mapped[float | None] = mapped_column(Float)
    timezone: Mapped[str | None] = mapped_column(String(64))
    locale: Mapped[str | None] = mapped_column(String(16))
    country: Mapped[str | None] = mapped_column(String(2))
    avatar_key: Mapped[str | None] = mapped_column(String(64))
    bio: Mapped[str | None] = mapped_column(Text)
    onboarded_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    last_active_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    ios_app_version: Mapped[str | None] = mapped_column(String(32))
    ios_device_model: Mapped[str | None] = mapped_column(String(64))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    user: Mapped[User] = relationship(back_populates="details")


class UserXpDaily(Base):
    """Per-day XP ledger. One row per (user, day). Daily XP = today's row,
    total XP = SUM across all rows. Friends leaderboard ranks by total."""

    __tablename__ = "user_xp_daily"

    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    day: Mapped[date] = mapped_column(Date, primary_key=True)
    xp: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    user: Mapped[User] = relationship(back_populates="xp_days")


class QuestCatalog(Base):
    """Definition table: every (metric, tier, duration) quest the system knows
    about, with its XP reward and the stretch factor used to compute a
    user-specific target from their 7-day baseline."""

    __tablename__ = "quest_catalog"

    id: Mapped[int] = mapped_column(primary_key=True)
    slug: Mapped[str] = mapped_column(String(64), nullable=False, unique=True)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    metric: Mapped[str] = mapped_column(String(32), nullable=False)
    tier: Mapped[str] = mapped_column(String(16), nullable=False)
    duration: Mapped[str] = mapped_column(String(16), nullable=False)
    stretch_factor: Mapped[float] = mapped_column(Float, nullable=False)
    xp_reward: Mapped[int] = mapped_column(Integer, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)


class UserQuest(Base):
    """A single quest assignment for a user. The user has a "pool" of these:
    `slot='active'` rows are the 4 the user is currently grinding;
    `slot='available'` rows are the alternatives they can swap to."""

    __tablename__ = "user_quests"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    catalog_id: Mapped[int] = mapped_column(
        ForeignKey("quest_catalog.id"), nullable=False
    )

    slot: Mapped[str] = mapped_column(String(16), nullable=False)            # 'active' | 'available'
    status: Mapped[str] = mapped_column(String(16), nullable=False, default="inProgress")
    target_value: Mapped[float] = mapped_column(Float, nullable=False)
    progress_value: Mapped[float] = mapped_column(Float, nullable=False, default=0)
    starts_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    assigned_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    user: Mapped[User] = relationship(back_populates="quests")
    catalog: Mapped[QuestCatalog] = relationship()
