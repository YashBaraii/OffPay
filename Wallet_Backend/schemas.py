# schemas.py
from pydantic import BaseModel, Field, condecimal, EmailStr
from typing import Optional
from uuid import UUID

Money = condecimal(max_digits=18, decimal_places=2)


class OfflineRequestIn(BaseModel):
    user_id: UUID
    mode: str  # "send" or "receive"
    amount: Money
    security_code: str  # raw code from app; server will hash it
    nonce: str
    local_txn_id: Optional[str] = None


class OfflineRequestOut(BaseModel):
    id: UUID
    status: str


class TransactionOut(BaseModel):
    id: UUID
    sender_id: UUID
    receiver_id: UUID
    amount: Money
    created_at: str


class CreateUserIn(BaseModel):
    email: EmailStr
    display_name: Optional[str] = None
    initial_balance: Optional[Money] = 0
