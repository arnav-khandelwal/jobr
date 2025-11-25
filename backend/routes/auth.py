from datetime import datetime
from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi import Request
from fastapi import Form
from motor.motor_asyncio import AsyncIOMotorDatabase

from models.user import UserCreate, UserPublic, Token, user_in_db_to_public
from utils.auth import hash_password, verify_password, create_access_token, get_current_user_id

router = APIRouter(prefix="/api/auth", tags=["auth"])


def get_db(request: Request) -> AsyncIOMotorDatabase:
    db = request.app.state.db
    if db is None:
        raise HTTPException(status_code=500, detail="Database not initialized")
    return db


@router.post("/signup", response_model=UserPublic, status_code=201)
async def signup(user: UserCreate, db: AsyncIOMotorDatabase = Depends(get_db)):
    # Debug (non-sensitive): log lengths & email pattern when validation passed
    try:
        print(f"[signup] email={user.email} password_len={len(user.password)} full_name_present={bool(user.full_name)}")
    except Exception:
        pass
    existing = await db.users.find_one({"email": user.email})
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")

    now = datetime.utcnow()
    doc = {
        "email": user.email,
        "full_name": user.full_name,
        "password_hash": hash_password(user.password),
        "created_at": now,
        "updated_at": now,
    }
    result = await db.users.insert_one(doc)
    doc["_id"] = result.inserted_id
    return user_in_db_to_public(doc)


@router.post("/signin", response_model=Token)
async def signin(
    username: str = Form(...),
    password: str = Form(...),
    db: AsyncIOMotorDatabase = Depends(get_db),
):
    user = await db.users.find_one({"email": username})
    if not user or not verify_password(password, user.get("password_hash", "")):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    token = create_access_token(str(user["_id"]))
    return Token(access_token=token)


@router.get("/me", response_model=UserPublic)
async def me(user_id: str = Depends(get_current_user_id), db: AsyncIOMotorDatabase = Depends(get_db)):
    try:
        obj_id = ObjectId(user_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid user id in token")
    user = await db.users.find_one({"_id": obj_id})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user_in_db_to_public(user)