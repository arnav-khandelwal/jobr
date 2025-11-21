# backend/main.py
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from typing import Optional
from datetime import datetime

from models.job import Job, JobResponse
from scrapers.naukri_scraper import NaukriScraper
from scrapers.remoteonly_scraper import RemoteOnlyScraper
from utils.data_processor import DataProcessor
from motor.motor_asyncio import AsyncIOMotorClient
from routes.auth import router as auth_router
from routes.parse_resume import router as parse_router
import os

app = FastAPI(
    title="JobScraper API",
    description="API for scraping job data from Naukri and RemoteOnly + Auth",
    version="1.1.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize scraper and processor
naukri_scraper = NaukriScraper()
remoteonly_scraper = RemoteOnlyScraper()
data_processor = DataProcessor()
app.include_router(auth_router)
app.include_router(parse_router)

@app.on_event("startup")
async def startup_event():
    mongo_uri = os.getenv("MONGO_URI", "mongodb://localhost:27017")
    client = AsyncIOMotorClient(mongo_uri)
    app.state.db = client[os.getenv("MONGO_DB_NAME", "jobr_db")]
    # Create unique index on email for users
    try:
        await app.state.db.users.create_index("email", unique=True)
    except Exception as e:
        print(f"Index creation error: {e}")

@app.on_event("shutdown")
async def shutdown_event():
    db = getattr(app.state, 'db', None)
    if db is not None:
        client = db.client
        client.close()

@app.get("/")
async def root():
    return {"message": "JobScraper API is running!", "status": "active"}

@app.get("/api/jobs", response_model=JobResponse)
async def get_jobs(
    search_term: str = Query(default="software developer", description="Job search term"),
    location: str = Query(default="India", description="Job location"),
    pages: int = Query(default=2, description="Number of pages to scrape", ge=1, le=5)
):
    try:
        all_jobs = []
        source_breakdown = {}

        # Use Naukri scraper for real job data
        try:
            naukri_jobs = naukri_scraper.scrape_jobs(search_term, location, pages)
            all_jobs.extend(naukri_jobs)
            source_breakdown["naukri"] = len(naukri_jobs)
        except Exception as e:
            print(f"Error with Naukri scraper: {e}")
            source_breakdown["naukri"] = 0

        # Use RemoteOnly scraper for remote jobs
        try:
            remote_jobs = remoteonly_scraper.scrape_jobs(search_term=search_term, location="remote", pages=1)
            all_jobs.extend(remote_jobs)
            source_breakdown["remoteonly"] = len(remote_jobs)
        except Exception as e:
            print(f"Error with RemoteOnly scraper: {e}")
            source_breakdown["remoteonly"] = 0

        # Remove duplicates
        unique_jobs = data_processor.remove_duplicates(all_jobs)

        return JobResponse(
            jobs=unique_jobs,
            total_count=len(unique_jobs),
            source_breakdown=source_breakdown,
            last_updated=datetime.now()
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error scraping jobs: {str(e)}")

@app.get("/api/health")
async def health_check():
    return {
        "status": "healthy",
        "timestamp": datetime.now(),
        "scrapers": {
            "naukri": "active",
            "remoteonly": "active"
        }
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)