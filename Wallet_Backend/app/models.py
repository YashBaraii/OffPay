from sqlalchemy import Column, String, Float, DateTime
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime

Base = declarative_base()


class Wallet(Base):
    __tablename__ = "wallets"
    user_id = Column(String, primary_key=True, index=True)
    balance = Column(Float, default=0.0)
    last_updated = Column(DateTime, default=datetime.utcnow)
    encrypted_keys = Column(String)


class Transaction(Base):
    __tablename__ = "transactions"
    txn_id = Column(String, primary_key=True, index=True)
    amount = Column(Float)
    payer_id = Column(String)
    payee_id = Column(String)
    timestamp = Column(DateTime, default=datetime.utcnow)
    status = Column(String)
    signature = Column(String)
    token = Column(String)
