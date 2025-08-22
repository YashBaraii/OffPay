from fastapi import APIRouter
from app.schemas import TransactionCreate, TransactionResponse
from app.models import Transaction
from app.utils import SessionLocal
from datetime import datetime

router = APIRouter()


@router.post("/transaction/sync", response_model=TransactionResponse)
def sync_transaction(txn: TransactionCreate):
    db = SessionLocal()
    db_txn = Transaction(
        txn_id=txn.txn_id,
        amount=txn.amount,
        payer_id=txn.payer_id,
        payee_id=txn.payee_id,
        token=txn.token,
        signature=txn.signature,
        timestamp=datetime.utcnow(),
        status="completed",
    )
    db.add(db_txn)
    db.commit()
    db.refresh(db_txn)
    return db_txn
