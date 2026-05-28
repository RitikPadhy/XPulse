from datetime import date, datetime

from sqlalchemy import (
    JSON,
    Boolean,
    CheckConstraint,
    Date,
    DateTime,
    Float,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.dialects.postgresql import JSONB
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
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    details: Mapped["UserDetail | None"] = relationship(
        back_populates="user", uselist=False, cascade="all, delete-orphan"
    )
    samples: Mapped[list["HealthSample"]] = relationship(
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


class HealthSample(Base):
    __tablename__ = "health_samples"
    __table_args__ = (
        UniqueConstraint(
            "user_id", "type", "start_date", "end_date",
            name="uq_sample_user_type_window",
        ),
        Index("ix_sample_user_type_start", "user_id", "type", "start_date"),
        Index("ix_sample_user_uuid", "user_id", "healthkit_uuid"),
        Index("ix_sample_ingested_at", "ingested_at"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )

    healthkit_uuid: Mapped[str | None] = mapped_column(Text)
    # 'quantity' | 'category' | 'workout' | 'correlation' | 'series'
    sample_category: Mapped[str] = mapped_column(
        String(32), nullable=False, default="quantity"
    )
    type: Mapped[str] = mapped_column(String(255), nullable=False)

    start_date: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    end_date: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)

    # HKQuantitySample
    value_quantity: Mapped[float | None] = mapped_column(Float)
    unit: Mapped[str | None] = mapped_column(String(64))

    # HKCategorySample (enum int — sleep stage, mindful, …)
    value_category: Mapped[int | None] = mapped_column(Integer)

    # HKWorkout
    workout_activity_type: Mapped[int | None] = mapped_column(Integer)
    workout_duration_seconds: Mapped[float | None] = mapped_column(Float)
    workout_total_distance_m: Mapped[float | None] = mapped_column(Float)
    workout_total_energy_kcal: Mapped[float | None] = mapped_column(Float)
    workout_total_flights: Mapped[int | None] = mapped_column(Integer)
    workout_total_swim_strokes: Mapped[int | None] = mapped_column(Integer)

    # Provenance
    source_name: Mapped[str | None] = mapped_column(String(255))
    source_bundle_id: Mapped[str | None] = mapped_column(String(255))
    source_version: Mapped[str | None] = mapped_column(String(64))
    source_operating_system: Mapped[str | None] = mapped_column(String(64))
    device_name: Mapped[str | None] = mapped_column(String(255))
    device_model: Mapped[str | None] = mapped_column(String(255))
    device_manufacturer: Mapped[str | None] = mapped_column(String(255))
    device_hardware_version: Mapped[str | None] = mapped_column(String(64))
    device_software_version: Mapped[str | None] = mapped_column(String(64))
    device_local_identifier: Mapped[str | None] = mapped_column(String(255))

    was_user_entered: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False
    )
    time_zone: Mapped[str | None] = mapped_column(String(64))

    # Free-form HKMetadata dict
    metadata_: Mapped[dict | None] = mapped_column("metadata", JSONB().with_variant(JSON(), "sqlite"))

    ingested_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    user: Mapped[User] = relationship(back_populates="samples")
