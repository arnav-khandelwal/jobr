# backend/models/job.py
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class Job(BaseModel):
    job_id: str
    job_title: str
    company_name: str
    location: str
    job_type: str
    salary: str
    experience_required: str
    skills: List[str]
    job_description: str
    posted_date: str
    apply_link: str
    source: str
    remote_friendly: bool
    company_logo_url: Optional[str] = None
    industry: Optional[str] = None
    education_required: Optional[str] = None
    scraped_at: datetime = datetime.now()

class JobResponse(BaseModel):
    jobs: List[Job]
    total_count: int
    source_breakdown: dict
    last_updated: datetime