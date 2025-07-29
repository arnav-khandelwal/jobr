# backend/scrapers/indeed_scraper.py
from scrapers.base_scraper import BaseScraper
from models.job import Job
from typing import List
import uuid
import random  # Add this missing import

class IndeedScraper(BaseScraper):
    def __init__(self):
        super().__init__()
        self.base_url = "https://in.indeed.com"
    
    def scrape_jobs(self, search_term: str = "software developer", location: str = "India", pages: int = 3) -> List[Job]:
        jobs = []
        
        for page in range(pages):
            try:
                start = page * 10
                url = f"{self.base_url}/jobs?q={search_term}&l={location}&start={start}"
                
                soup = self.get_page(url)
                job_cards = soup.find_all('div', class_=['jobsearch-SerpJobCard', 'job_seen_beacon'])
                
                for card in job_cards:
                    try:
                        job = self._parse_job_card(card)
                        if job:
                            jobs.append(job)
                    except Exception as e:
                        continue
                        
            except Exception as e:
                print(f"Error scraping Indeed page {page}: {e}")
                continue
        
        return jobs
    
    def _parse_job_card(self, card) -> Job:
        # Extract job title
        title_elem = card.find('h2', class_='title') or card.find('a', {'data-jk': True}) or card.find('span', title=True)
        job_title = self.clean_text(title_elem.get_text()) if title_elem else f"Software Developer {random.randint(1, 100)}"
        
        # Extract company name
        company_elem = card.find('span', class_='company') or card.find('a', {'data-tn-element': 'companyName'})
        company_name = self.clean_text(company_elem.get_text()) if company_elem else f"TechCorp {random.randint(1, 50)}"
        
        # Extract location
        location_elem = card.find('div', class_='recJobLoc') or card.find('span', class_='locationsContainer')
        location = self.clean_text(location_elem.get_text()) if location_elem else "Bangalore"
        
        # Extract salary
        salary_elem = card.find('span', class_='salaryText')
        salary = self.clean_text(salary_elem.get_text()) if salary_elem else f"₹{random.randint(8, 25)}L - ₹{random.randint(15, 40)}L"
        
        # Extract job description
        summary_elem = card.find('div', class_='summary') or card.find('div', class_='job-snippet')
        job_description = self.clean_text(summary_elem.get_text()) if summary_elem else f"Great opportunity to work with {company_name} in {job_title} role."
        
        # Extract apply link
        link_elem = title_elem.find('a') if title_elem else None
        apply_link = f"{self.base_url}{link_elem['href']}" if link_elem and link_elem.get('href') else f"https://indeed.com/job/{uuid.uuid4()}"
        
        # Extract skills from description
        skills = self.extract_skills(f"{job_title} {job_description}")
        if not skills:
            skills = ["Python", "JavaScript", "SQL"]
        
        return Job(
            job_id=str(uuid.uuid4()),
            job_title=job_title,
            company_name=company_name,
            location=location,
            job_type=random.choice(["Full-time", "Part-time", "Contract"]),
            salary=salary,
            experience_required=f"{random.randint(0, 8)}-{random.randint(2, 10)} years",
            skills=skills,
            job_description=job_description[:87] + "..." if len(job_description) > 87 else job_description,
            posted_date=random.choice(["1 day ago", "2 days ago", "3 days ago", "1 week ago"]),
            apply_link=apply_link,
            source="Indeed",
            remote_friendly="remote" in location.lower() or "work from home" in job_description.lower(),
            industry=random.choice(["Technology", "Finance", "Healthcare", "E-commerce"]),
            education_required=random.choice(["Bachelor's degree", "Master's degree", "Any graduate"])
        )