# backend/routes/recommendations.py
"""Endpoint to recommend best jobs using Gemini based on resume + job list.

Expected request JSON:
{
  "resume_data": { ... },
  "jobs": [ { Job model dict }, ... ],
  "max_recommendations": 5
}

Returns JobResponse with top N jobs.
"""
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import List, Dict, Any
import os, json, re
from dotenv import load_dotenv

# Ensure .env is loaded (in case main didn't run first in certain execution contexts)
load_dotenv()
from datetime import datetime

from models.job import Job, JobResponse

router = APIRouter()

class RecommendationRequest(BaseModel):
    resume_data: Dict[str, Any]
    jobs: List[Job] = Field(default_factory=list)
    max_recommendations: int = 5

"""Gemini model selection.

The newer google-genai client typically expects bare model names like
"gemini-1.5-flash-latest" rather than the older "models/" prefixed form.
We keep flexibility: if a user sets GEMINI_MODEL with or without the prefix
we will try both.
"""
GEMINI_MODEL = "gemini-2.5-flash"

# Lazy init for Gemini v1 client
_gen_client = None

def _get_gemini_client():
    global _gen_client
    if _gen_client is not None:
        return _gen_client
    print(f"Initializing Gemini client (will read GEMINI_API_KEY from environment) with model {GEMINI_MODEL}")
    try:
        from google import genai
        # Create client without explicit api_key; genai.Client will read GEMINI_API_KEY from env
        _gen_client = genai.Client()
        return _gen_client
    except Exception as e:
        raise RuntimeError(f"Gemini init failed: {e}")

@router.post("/api/recommendations", response_model=JobResponse)
async def recommend_jobs(payload: RecommendationRequest):
    if not payload.jobs:
        raise HTTPException(status_code=400, detail="No jobs provided")
    if not payload.resume_data:
        raise HTTPException(status_code=400, detail="No resume_data provided")

    max_n = max(1, min(payload.max_recommendations, 10))

    # Build condensed job list for prompt (avoid very long descriptions)
    compact_jobs = []
    for j in payload.jobs[:100]:  # safety cap
        compact_jobs.append({
            "job_id": j.job_id,
            "title": j.job_title,
            "company": j.company_name,
            "skills": j.skills[:8],
            "experience": j.experience_required,
            "location": j.location,
            "description": j.job_description[:180],
        })

    resume_summary = {
        k: payload.resume_data.get(k)
        for k in ["name", "email", "phone", "skills", "education", "experience"]
        if k in payload.resume_data
    }

    prompt = (
        "You are a job matching engine. Given a resume summary and a list of jobs, "
        "return EXACT JSON: {\"recommended_job_ids\": [\"id1\", ...]} containing up to "
        f"{max_n} best matching job_ids. Prefer strong skill overlap, appropriate experience, and location fit. "
        "Do not include explanations, ONLY valid JSON.\n\n"
        f"Resume: {json.dumps(resume_summary)}\nJobs: {json.dumps(compact_jobs)}"
    )

    recommended_ids: List[str] = []
    try:
        client = _get_gemini_client()
        from google import genai  # ensure module available in runtime context
        # Use the single model specified by GEMINI_MODEL (gemini-2.5-flash)
        response = client.models.generate_content(model=GEMINI_MODEL, contents=prompt)
        text = getattr(response, 'text', '') or ''
        # Extract JSON block
        match = re.search(r"\{[^{}]*recommended_job_ids[^{}]*\}", text, re.IGNORECASE)
        if match:
            block = match.group(0)
            try:
                parsed = json.loads(block)
                ids = parsed.get("recommended_job_ids", [])
                if isinstance(ids, list):
                    recommended_ids = [str(i) for i in ids]
            except Exception:
                pass
    except Exception as e:
        print(f"Gemini recommendation error: {e}")

    # Fallback: simple heuristic if Gemini fails or returns nothing
    if not recommended_ids:
        skill_set = set(map(str.lower, payload.resume_data.get("skills", []) or []))
        scored = []
        for j in payload.jobs:
            match_count = sum(1 for s in j.skills if s.lower() in skill_set)
            scored.append((j, match_count))
        scored.sort(key=lambda t: t[1], reverse=True)
        recommended_jobs = [t[0] for t in scored[:max_n]]
    else:
        id_set = set(recommended_ids)
        recommended_jobs = [j for j in payload.jobs if j.job_id in id_set]
        # Preserve requested order
        ordering = {rid: idx for idx, rid in enumerate(recommended_ids)}
        recommended_jobs.sort(key=lambda j: ordering.get(j.job_id, 9999))
        recommended_jobs = recommended_jobs[:max_n]

    return JobResponse(
        jobs=recommended_jobs,
        total_count=len(recommended_jobs),
        source_breakdown={"gemini": len(recommended_jobs)},
        last_updated=datetime.now()
    )
