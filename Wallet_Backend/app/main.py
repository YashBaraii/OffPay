from fastapi import FastAPI
from app.routes import auth, wallet, transaction

app = FastAPI(title="Offline NFC UPI Backend")

app.include_router(auth.router, prefix="/auth")
app.include_router(wallet.router)
app.include_router(transaction.router)

if __name__ == "__main__":
    import uvicorn

    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
