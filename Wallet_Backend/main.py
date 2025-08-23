# main.py
import asyncio
import asyncpg
from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
from uuid import UUID
from schemas import OfflineRequestIn, CreateUserIn, OfflineRequestOut, TransactionOut
from utils import send_email_async
from crud import create_offline_request, find_pair_and_execute
from models import (
    User,
    OfflineRequest,
    TransactionHistory,
)  # keep your pydantic/sql models
from decouple import config

app = FastAPI(title="Offline-Pay Pairing Service")

# ---- DATABASE CONNECTION ----
DATABASE_CONFIG = {
    "user": config("DB_USER"),  # from Supabase
    "password": config("DB_PASS"),  # your Supabase DB password
    "database": config("DB_NAME"),  # default db
    "host": config("DB_HOST"),  # pooled host
    "port": config("DB_PORT"),  # pooled port
    "ssl": "require",  # Supabase requires SSL
}

db_pool: asyncpg.Pool | None = None


@app.on_event("startup")
async def startup():
    global db_pool
    db_pool = await asyncpg.create_pool(**DATABASE_CONFIG)
    print("✅ Connected to Supabase PostgreSQL")


@app.on_event("shutdown")
async def shutdown():
    global db_pool
    if db_pool:
        await db_pool.close()


# ---- ROUTES ----
@app.post("/users", response_model=dict)
async def create_user(payload: CreateUserIn):
    async with db_pool.acquire() as conn:
        row = await conn.fetchrow(
            """
            INSERT INTO users (email, display_name, balance)
            VALUES ($1, $2, $3)
            RETURNING id, email, balance
            """,
            payload.email,
            payload.display_name,
            payload.initial_balance,
        )
        return {
            "id": str(row["id"]),
            "email": row["email"],
            "balance": str(row["balance"]),
        }


@app.post("/submit_request", response_model=OfflineRequestOut)
async def submit_request(payload: OfflineRequestIn):
    async with db_pool.acquire() as conn:
        # Insert offline request
        new_req = await conn.fetchrow(
            """
            INSERT INTO offline_requests (user_id, mode, amount, security_code, nonce, local_txn_id, status)
            VALUES ($1, $2, $3, $4, $5, $6, 'pending')
            RETURNING id, status
            """,
            payload.user_id,
            payload.mode,
            payload.amount,
            payload.security_code,
            payload.nonce,
            payload.local_txn_id,
        )
        # 🔹 Instead of SQLAlchemy transaction logic, you’ll reimplement `find_pair_and_execute` in raw SQL
        # For now return request
        return OfflineRequestOut(id=new_req["id"], status=new_req["status"])


@app.get("/tx/{txn_id}", response_model=TransactionOut)
async def get_txn(txn_id: UUID):
    async with db_pool.acquire() as conn:
        row = await conn.fetchrow(
            "SELECT * FROM transaction_history WHERE id = $1", txn_id
        )
        if not row:
            raise HTTPException(status_code=404, detail="txn not found")

        return {
            "id": str(row["id"]),
            "sender_id": str(row["sender_id"]),
            "receiver_id": str(row["receiver_id"]),
            "amount": str(row["amount"]),
            "created_at": row["created_at"].isoformat(),
        }
