import uuid

from sqlalchemy import (
    Column,
    String,
    Text,
    Date,
    Time,
    ForeignKey,
    TIMESTAMP,
    func,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from .database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())

    devices = relationship("UserDevice", back_populates="user")
    signs = relationship("UserSign", back_populates="user")


class UserDevice(Base):
    __tablename__ = "user_devices"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    fcm_token = Column(Text, nullable=False)
    lang = Column(String(2), nullable=False, default="ru")
    # Время пуша по Москве
    push_time = Column(Time, nullable=False)
    # Дата последнего отправленного пуша (NULL, если ещё не отправляли)
    last_push_date = Column(Date, nullable=True)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="devices")


class Horoscope(Base):
    __tablename__ = "horoscopes"

    id = Column(String, primary_key=True)
    sign = Column(String(20), nullable=False)
    date = Column(Date, nullable=False)
    lang = Column(String(2), nullable=False)
    title = Column(Text)
    text = Column(Text, nullable=False)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())


class UserSign(Base):
    __tablename__ = "user_signs"

    user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        primary_key=True,
    )
    sign = Column(String(20), primary_key=True)

    user = relationship("User", back_populates="signs")
