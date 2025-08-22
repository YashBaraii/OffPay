from pydantic import BaseModel
from datetime import datetime


class WalletCreate(BaseModel):
    user_id: str
    encrypted_keys: str


class WalletResponse(BaseModel):
    user_id: str
    balance: float
    last_updated: datetime

    class Config:
        orm_mode = True


class TransactionCreate(BaseModel):
    txn_id: str
    amount: float
    payer_id: str
    payee_id: str
    token: str
    signature: str


class TransactionResponse(BaseModel):
    txn_id: str
    amount: float
    payer_id: str
    payee_id: str
    timestamp: datetime
    status: str

    class Config:
        orm_mode = True
