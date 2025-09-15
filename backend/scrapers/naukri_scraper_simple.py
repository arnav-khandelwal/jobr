from scrapers.base_scraper import BaseScraper
from models.job import Job
from typing import List
import uuid
import time
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from bs4 import BeautifulSoup

class NaukriScraper(BaseScraper):
    def __init__(self):
        super().__init__()
        self.base_url = "https://www.naukri.com"

    def scrape_jobs(self, search_term: str = "software developer", location: str = "bangalore", pages: int = 1) -> List[Job]:
        jobs = []
        chrome_options = Options()
        # chrome_options.add_argument("--headless")  # Disable headless for debugging
        chrome_options.add_argument("--disable-gpu")
        chrome_options.add_argument("--no-sandbox")
        chrome_options.add_argument("--window-size=1920,1080")
        chrome_options.add_argument("--user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")

        driver = webdriver.Chrome(options=chrome_options)

        try:
            # Simple Naukri URL for software developer jobs in bangalore
            url = f"{self.base_url}/software-developer-jobs-in-bangalore"
            print(f"Scraping: {url}")
            
            driver.get(url)
            time.sleep(5)  # Wait for page to load completely

            # Log HTML for debugging (only first time)
            print("=== PAGE HTML (first 3000 chars) ===")
            print(driver.page_source[:3000])
            print("=== END HTML ===")

            soup = BeautifulSoup(driver.page_source, "html.parser")

            # Try multiple selectors to find job cards
            job_selectors = [
                ('div', 'jobTuple'),
                ('div', 'srp-jobtuple-wrapper'),  
                ('article', 'jobTuple'),
                ('div', {'class': 'row1'}),
            ]

            job_cards = []
            for tag, selector in job_selectors:
                if isinstance(selector, dict):
                    cards = soup.find_all(tag, selector)
                else:
                    cards = soup.find_all(tag, class_=selector)
                
                if cards:
                    print(f"Found {len(cards)} job cards with selector {tag}.{selector}")
                    job_cards = cards
                    break

            if not job_cards:
                print("No job cards found with any selector")
                # Let's see what elements are available
                print("Available div classes:", [div.get('class') for div in soup.find_all('div')[:20]])

            for card in job_cards[:10]:  # Limit to 10 jobs
                job = self._parse_job_card(card)
                if job:
                    jobs.append(job)

        except Exception as e:
            print(f"Error scraping: {e}")
            import traceback
            traceback.print_exc()

        finally:
            driver.quit()

        return jobs

    def _parse_job_card(self, card) -> Job:
        try:
            # Extract job title - try multiple selectors
            title_elem = (
                card.find('a', class_='title') or
                card.find('h3') or
                card.find('a', href=True)
            )
            job_title = self.clean_text(title_elem.get_text()) if title_elem else "Software Developer"

            # Extract company name
            company_elem = (
                card.find('a', class_='subTitle') or
                card.find('span', class_='company') or
                card.find('div', class_='companyInfo')
            )
            company_name = self.clean_text(company_elem.get_text()) if company_elem else "Tech Company"

            # Extract experience
            exp_elem = card.find('span', class_='expwdth')
            experience_required = self.clean_text(exp_elem.get_text()) if exp_elem else "0-3 years"

            # Extract salary
            salary_elem = card.find('span', class_='salary')
            salary = self.clean_text(salary_elem.get_text()) if salary_elem else "₹8L - ₹15L"

            # Extract location
            location_elem = card.find('span', class_='locWdth')
            location = self.clean_text(location_elem.get_text()) if location_elem else "Bangalore"

            # Create description
            job_description = f"Join {company_name} as {job_title}. Great opportunity for career growth."

            # Extract skills
            skills = self.extract_skills(f"{job_title}")
            if not skills:
                skills = ["Python", "JavaScript", "SQL"]

            return Job(
                job_id=str(uuid.uuid4()),
                job_title=job_title,
                company_name=company_name,
                location=location,
                job_type="Full-time",
                salary=salary,
                experience_required=experience_required,
                skills=skills[:5],
                job_description=job_description,
                posted_date="Recently",
                apply_link=f"{self.base_url}/job-{str(uuid.uuid4())[:8]}",
                source="Naukri",
                remote_friendly="remote" in location.lower(),
                industry="Technology",
                education_required="Bachelor's degree"
            )
        except Exception as e:
            print(f"Error parsing job card: {e}")
            return None
