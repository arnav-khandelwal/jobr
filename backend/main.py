# backend/main.py
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from typing import List, Optional
from datetime import datetime

from models.job import Job, JobResponse
from scrapers.indeed_scraper import IndeedScraper
from scrapers.mock_scraper import MockScraper
from utils.data_processor import DataProcessor

app = FastAPI(
    title="JobScraper API",
    description="API for scraping job data from various job portals",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize scrapers
indeed_scraper = IndeedScraper()
mock_scraper = MockScraper()
data_processor = DataProcessor()

@app.get("/")
async def root():
    return {"message": "JobScraper API is running!", "status": "active"}

@app.get("/api/jobs", response_model=JobResponse)
async def get_jobs(
    search_term: str = Query(default="software developer", description="Job search term"),
    location: str = Query(default="India", description="Job location"),
    pages: int = Query(default=2, description="Number of pages to scrape", ge=1, le=5),
    source: Optional[str] = Query(default=None, description="Specific source")
):
    try:
        all_jobs = []
        source_breakdown = {}
        
        # Use mock scraper for reliable data
        try:
            mock_jobs = mock_scraper.scrape_jobs(search_term, location, pages)
            all_jobs.extend(mock_jobs)
            source_breakdown["mock"] = len(mock_jobs)
        except Exception as e:
            print(f"Error with mock scraper: {e}")
            source_breakdown["mock"] = 0
        
        # Try Indeed scraper as backup
        try:
            indeed_jobs = indeed_scraper.scrape_jobs(search_term, location, 1)
            all_jobs.extend(indeed_jobs)
            source_breakdown["indeed"] = len(indeed_jobs)
        except Exception as e:
            print(f"Error scraping Indeed: {e}")
            source_breakdown["indeed"] = 0
        
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
            "mock": "active",
            "indeed": "active"
        }
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)