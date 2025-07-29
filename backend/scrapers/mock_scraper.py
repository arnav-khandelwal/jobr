# backend/scrapers/mock_scraper.py
from scrapers.base_scraper import BaseScraper
from models.job import Job
from typing import List
import uuid
import random

class MockScraper(BaseScraper):
    def __init__(self):
        super().__init__()
        self.companies = [
            "Google", "Microsoft", "Amazon", "Apple", "Meta", "Netflix", "Tesla",
            "Flipkart", "Zomato", "Paytm", "Ola", "Swiggy", "BYJU'S", "Razorpay",
            "Freshworks", "Zoho", "InMobi", "PhonePe", "Cred", "Dream11"
        ]
        
        self.job_titles = [
            "Flutter Developer", "React Developer", "Node.js Developer", "Python Developer",
            "Data Scientist", "ML Engineer", "DevOps Engineer", "Product Manager",
            "UI/UX Designer", "Backend Engineer", "Frontend Developer", "Full Stack Developer",
            "Android Developer", "iOS Developer", "QA Engineer", "Business Analyst"
        ]
        
        self.locations = [
            "Bangalore", "Mumbai", "Delhi", "Hyderabad", "Chennai", "Pune", "Gurgaon", "Remote"
        ]
    
    def scrape_jobs(self, search_term: str = "software developer", location: str = "India", pages: int = 3) -> List[Job]:
        jobs = []
        num_jobs = pages * 8  # Generate 8 jobs per page
        
        for i in range(num_jobs):
            job = self._generate_mock_job()
            jobs.append(job)
        
        return jobs
    
    def _generate_mock_job(self) -> Job:
        job_title = random.choice(self.job_titles)
        company_name = random.choice(self.companies)
        location = random.choice(self.locations)
        
        skills_map = {
            "Flutter Developer": ["Flutter", "Dart", "Firebase", "REST APIs"],
            "React Developer": ["React", "JavaScript", "Redux", "Node.js"],
            "Python Developer": ["Python", "Django", "Flask", "PostgreSQL"],
            "Data Scientist": ["Python", "Machine Learning", "TensorFlow", "SQL"],
            "DevOps Engineer": ["Docker", "Kubernetes", "AWS", "Jenkins"],
        }
        
        base_skills = skills_map.get(job_title, ["JavaScript", "Python", "SQL"])
        skills = base_skills + random.sample(["Git", "Docker", "AWS", "MongoDB"], 2)
        
        descriptions = [
            f"Join {company_name} as a {job_title}. Work on cutting-edge technology.",
            f"Exciting opportunity at {company_name} for {job_title} role with growth potential.",
            f"Build innovative solutions as {job_title} at {company_name}. Remote-friendly.",
            f"Scale products used by millions as {job_title} at {company_name}.",
        ]
        
        return Job(
            job_id=str(uuid.uuid4()),
            job_title=job_title,
            company_name=company_name,
            location=location,
            job_type=random.choice(["Full-time", "Part-time", "Contract", "Internship"]),
            salary=f"₹{random.randint(5, 30)}L - ₹{random.randint(15, 50)}L",
            experience_required=f"{random.randint(0, 5)}-{random.randint(2, 8)} years",
            skills=skills[:5],
            job_description=random.choice(descriptions),
            posted_date=random.choice(["1 day ago", "2 days ago", "3 days ago", "1 week ago", "2 weeks ago"]),
            apply_link=f"https://{company_name.lower()}.com/careers/{str(uuid.uuid4())[:8]}",
            source="JobBoard",
            remote_friendly=location == "Remote" or random.choice([True, False]),
            industry=random.choice(["Technology", "Finance", "E-commerce", "AI/ML", "SaaS"]),
            education_required=random.choice(["Bachelor's degree", "Master's degree", "Any graduate", "Not specified"])
        )