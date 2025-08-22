from fastapi import APIRouter, Depends
from app.schemas import WalletCreate, WalletResponse
from app.models import Wallet
from app.utils import SessionLocal

router = APIRouter()


@router.post("/wallet/create", response_model=WalletResponse)
def create_wallet(wallet: WalletCreate):
    db = SessionLocal()
    db_wallet = Wallet(user_id=wallet.user_id, encrypted_keys=wallet.encrypted_keys)
    db.add(db_wallet)
    db.commit()
    db.refresh(db_wallet)
    return db_wallet
