# backend/utils/data_processor.py
from typing import List
from models.job import Job
import hashlib

class DataProcessor:
    @staticmethod
    def remove_duplicates(jobs: List[Job]) -> List[Job]:
        seen = set()
        unique_jobs = []
        
        for job in jobs:
            job_hash = hashlib.md5(
                f"{job.job_title.lower()}{job.company_name.lower()}{job.location.lower()}".encode()
            ).hexdigest()
            
            if job_hash not in seen:
                seen.add(job_hash)
                unique_jobs.append(job)
        
        return unique_jobs
    
    @staticmethod
    def filter_jobs(jobs: List[Job], location: str = None, job_type: str = None) -> List[Job]:
        filtered = jobs
        
        if location:
            filtered = [job for job in filtered if location.lower() in job.location.lower()]
        
        if job_type:
            filtered = [job for job in filtered if job_type.lower() in job.job_type.lower()]
        
        return filtered