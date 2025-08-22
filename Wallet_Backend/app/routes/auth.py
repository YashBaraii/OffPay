from fastapi import APIRouter, Depends, HTTPException
from jose import JWTError, jwt
from datetime import datetime, timedelta
from decouple import config

router = APIRouter()


def create_access_token(data: dict, expires_delta: timedelta = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (
        expires_delta or timedelta(minutes=int(config("ACCESS_TOKEN_EXPIRE_MINUTES")))
    )
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(
        to_encode, config("JWT_SECRET_KEY"), algorithm=config("ALGORITHM")
    )
    return encoded_jwt
