from datetime import datetime
from typing import List
from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException, Request
from motor.motor_asyncio import AsyncIOMotorDatabase

from models.application import ApplicationCreate, ApplicationPublic, application_doc_to_public
from utils.auth import get_current_user_id

router = APIRouter(prefix="/api/applications", tags=["applications"])


def get_db(request: Request) -> AsyncIOMotorDatabase:
    db = request.app.state.db
    if db is None:
        raise HTTPException(status_code=500, detail="Database not initialized")
    return db


@router.post("/", response_model=ApplicationPublic, status_code=201)
async def create_application(
    payload: ApplicationCreate,
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_db),
):
    # Prevent duplicate application per user+job (idempotent)
    existing = await db.applications.find_one({"user_id": ObjectId(user_id), "job_id": payload.job_id})
    if existing:
        # Return existing record instead of error
        return application_doc_to_public(existing)

    doc = {
        "user_id": ObjectId(user_id),
        "status": "applied",
        "applied_at": datetime.utcnow(),
        # Embedded job snapshot
        "job_id": payload.job_id,
        "job_title": payload.job_title,
        "company_name": payload.company_name,
        "source": payload.source,
        "apply_link": payload.apply_link,
        "location": payload.location,
        "job_type": payload.job_type,
        "salary": payload.salary,
        "experience_required": payload.experience_required,
        "skills": payload.skills,
    }
    result = await db.applications.insert_one(doc)
    doc["_id"] = result.inserted_id
    return application_doc_to_public(doc)


@router.get("/", response_model=List[ApplicationPublic])
async def list_applications(
    user_id: str = Depends(get_current_user_id),
    db: AsyncIOMotorDatabase = Depends(get_db),
):
    cursor = db.applications.find({"user_id": ObjectId(user_id)}).sort("applied_at", -1)
    records = []
    async for doc in cursor:
        records.append(application_doc_to_public(doc))
    return records
