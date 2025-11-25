from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field


class ApplicationCreate(BaseModel):
    """Incoming application creation payload from client.
    We embed key job fields so the application list can render without re-querying jobs.
    """
    job_id: str = Field(..., description="Unique job identifier")
    job_title: str
    company_name: str
    source: str
    apply_link: str
    location: Optional[str] = None
    job_type: Optional[str] = None
    salary: Optional[str] = None
    experience_required: Optional[str] = None
    skills: Optional[List[str]] = None


class ApplicationPublic(BaseModel):
    id: str
    user_id: str
    status: str = "applied"
    applied_at: datetime
    # Embedded job snapshot
    job_id: str
    job_title: str
    company_name: str
    source: str
    apply_link: str
    location: Optional[str] = None
    job_type: Optional[str] = None
    salary: Optional[str] = None
    experience_required: Optional[str] = None
    skills: Optional[List[str]] = None


def application_doc_to_public(doc: dict) -> ApplicationPublic:
    return ApplicationPublic(
        id=str(doc.get("_id")),
        user_id=str(doc.get("user_id")),
        status=doc.get("status", "applied"),
        applied_at=doc.get("applied_at"),
        job_id=doc.get("job_id"),
        job_title=doc.get("job_title"),
        company_name=doc.get("company_name"),
        source=doc.get("source"),
        apply_link=doc.get("apply_link"),
        location=doc.get("location"),
        job_type=doc.get("job_type"),
        salary=doc.get("salary"),
        experience_required=doc.get("experience_required"),
        skills=doc.get("skills"),
    )
