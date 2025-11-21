import os
from datetime import datetime, timedelta
from typing import Optional

from jose import jwt, JWTError
from passlib.context import CryptContext
from fastapi import HTTPException, status, Depends
from fastapi.security import OAuth2PasswordBearer

"""Authentication utilities: hashing & JWT.

We switch default hashing to Argon2 to avoid bcrypt backend issues
observed (ValueError & missing attributes). We keep bcrypt listed so
previously stored bcrypt hashes (if any) can still verify; new hashes
are Argon2.
"""
pwd_context = CryptContext(schemes=["argon2", "bcrypt"], default="argon2", deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/signin")

SECRET_KEY = os.getenv("JWT_SECRET", "dev-secret-key-change-me")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("JWT_EXPIRE_MINUTES", "60"))


def hash_password(password: str) -> str:
    # Argon2 has no 72-byte limit; we rely on CryptContext default (argon2).
    # If default changes or we drop argon2, reintroduce length checks as needed.
    return pwd_context.hash(password)


def verify_password(password: str, password_hash: str) -> bool:
    return pwd_context.verify(password, password_hash)


def create_access_token(sub: str) -> str:
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    payload = {"sub": sub, "exp": expire}
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


def decode_token(token: str) -> Optional[str]:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload.get("sub")
    except JWTError:
        return None


async def get_current_user_id(token: str = Depends(oauth2_scheme)) -> str:
    user_id = decode_token(token)
    if not user_id:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired token")
    return user_id