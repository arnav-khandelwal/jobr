from datetime import datetime
from typing import Optional
from pydantic import BaseModel, EmailStr, Field


class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)
    full_name: Optional[str] = None


class UserInDB(BaseModel):
    id: str
    email: EmailStr
    full_name: Optional[str] = None
    password_hash: str
    created_at: datetime
    updated_at: datetime


class UserPublic(BaseModel):
    id: str
    email: EmailStr
    full_name: Optional[str] = None
    created_at: datetime


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


def user_in_db_to_public(doc: dict) -> UserPublic:
    return UserPublic(
        id=str(doc.get("_id")),
        email=doc["email"],
        full_name=doc.get("full_name"),
        created_at=doc["created_at"],
    )