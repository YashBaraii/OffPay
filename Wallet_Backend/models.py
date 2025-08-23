# models.py
from sqlalchemy import (
    Column,
    Float,
    Integer,
    String,
    Numeric,
    Text,
    ForeignKey,
    DateTime,
    Enum,
    JSON,
    UniqueConstraint,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from sqlalchemy.ext.declarative import declarative_base
import uuid

Base = declarative_base()


class User(Base):
    __tablename__ = "users"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String, unique=True, nullable=False)
    display_name = Column(String)
    balance = Column(Numeric(18, 2), nullable=False, default=0)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class OfflineRequest(Base):
    __tablename__ = "offline_requests"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    mode = Column(String, nullable=False)  # 'send' | 'receive'
    amount = Column(Numeric(18, 2), nullable=False)
    security_hash = Column(Text, nullable=False)
    nonce = Column(String, nullable=False)
    local_txn_id = Column(String)
    status = Column(String, nullable=False, default="pending")  # pending|paired|failed
    paired_txn_id = Column(UUID(as_uuid=True))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    __table_args__ = (
        UniqueConstraint("security_hash", "nonce", name="u_security_nonce"),
    )


class TransactionHistory(Base):
    __tablename__ = "transaction_history"

    id = Column(Integer, primary_key=True, index=True)
    sender_id = Column(Integer, ForeignKey("users.id"))
    receiver_id = Column(Integer, ForeignKey("users.id"))
    amount = Column(Float, nullable=False)
    status = Column(String, default="pending")
    created_at = Column(DateTime, server_default=func.now())
    details = Column(JSON, default={})  # ✅ renamed from metadata
