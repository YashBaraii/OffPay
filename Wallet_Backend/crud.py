# crud.py
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, insert, update, and_
from models import OfflineRequest, User, TransactionHistory
from utils import hash_security_code
from sqlalchemy.exc import NoResultFound
from decimal import Decimal
import sqlalchemy
from sqlalchemy import func


async def create_offline_request(db: AsyncSession, req_data):
    # req_data: schemas.OfflineRequestIn
    sec_hash = hash_security_code(req_data.security_code)
    new = OfflineRequest(
        user_id=req_data.user_id,
        mode=req_data.mode,
        amount=req_data.amount,
        security_hash=sec_hash,
        nonce=req_data.nonce,
        local_txn_id=req_data.local_txn_id,
        status="pending",
    )
    db.add(new)
    await db.flush()  # populate new.id
    return new


async def find_pair_and_execute(
    db: AsyncSession, new_req: OfflineRequest, send_email_fn
):
    """
    Try to find a counterpart request with same security_hash and opposite mode and status pending.
    If found, execute transaction atomically (DB transaction).
    """
    target_mode = "receive" if new_req.mode == "send" else "send"

    # Find matching pending request
    q = (
        select(OfflineRequest)
        .where(
            OfflineRequest.security_hash == new_req.security_hash,
            OfflineRequest.mode == target_mode,
            OfflineRequest.status == "pending",
            OfflineRequest.amount == new_req.amount,
        )
        .order_by(OfflineRequest.created_at.asc())
        .limit(1)
        .with_for_update(skip_locked=True)
    )

    result = await db.execute(q)
    match = result.scalar_one_or_none()

    if not match:
        return None  # no match yet

    # Now perform transfer, but we must determine which is sender/receiver
    if new_req.mode == "send":
        sender_req = new_req
        receiver_req = match
    else:
        sender_req = match
        receiver_req = new_req

    # Lock sender and receiver user rows to prevent race
    sender_user = (
        await db.execute(
            select(User).where(User.id == sender_req.user_id).with_for_update()
        )
    ).scalar_one()
    receiver_user = (
        await db.execute(
            select(User).where(User.id == receiver_req.user_id).with_for_update()
        )
    ).scalar_one()

    amt = Decimal(sender_req.amount)

    if sender_user.balance < amt:
        # mark both requests failed due to insufficient funds
        sender_req.status = "failed"
        receiver_req.status = "failed"
        await db.flush()
        return {"error": "insufficient_funds"}

    # Debit/Credit
    sender_user.balance = sqlalchemy.cast(
        sender_user.balance - amt, sqlalchemy.Numeric(18, 2)
    )
    receiver_user.balance = sqlalchemy.cast(
        receiver_user.balance + amt, sqlalchemy.Numeric(18, 2)
    )

    # Create transaction history row
    txn = TransactionHistory(
        sender_id=sender_user.id,
        receiver_id=receiver_user.id,
        amount=amt,
        metadata={
            "sender_local_txn_id": str(sender_req.local_txn_id),
            "receiver_local_txn_id": str(receiver_req.local_txn_id),
            "security_hash": new_req.security_hash,
        },
    )
    db.add(txn)
    await db.flush()

    # Mark requests paired
    sender_req.status = "paired"
    receiver_req.status = "paired"
    sender_req.paired_txn_id = txn.id
    receiver_req.paired_txn_id = txn.id

    await db.flush()

    # Send emails (background)
    try:
        # fetch emails
        s_email = sender_user.email
        r_email = receiver_user.email
        await send_email_fn(
            s_email,
            "Debit: Amount deducted",
            f"Your account debited by {amt}. Txn id: {txn.id}",
        )
        await send_email_fn(
            r_email,
            "Credit: Amount credited",
            f"Your account credited by {amt}. Txn id: {txn.id}",
        )
    except Exception as e:
        # don't rollback transaction on email failure; but log
        print("Email send error:", e)

    return txn
