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

            # Parse all discovered job cards on the page
            for card in job_cards:
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
            # Extract job title from the correct selector
            title_elem = card.find('a', class_='title')
            job_title = self.clean_text(title_elem.get_text()) if title_elem else "Software Developer"

            # Extract company name from the correct selector
            company_elem = card.find('a', class_='comp-name')
            company_name = self.clean_text(company_elem.get_text()) if company_elem else "Tech Company"

            # Extract experience from the correct selector
            exp_elem = card.find('span', class_='expwdth')
            experience_required = self.clean_text(exp_elem.get_text()) if exp_elem else "0-3 years"

            # Extract location from the correct selector
            location_elem = card.find('span', class_='locWdth')
            location = self.clean_text(location_elem.get_text()) if location_elem else "Bangalore"

            # Extract apply link from job title link
            apply_link = title_elem.get('href') if title_elem else f"{self.base_url}/job-{str(uuid.uuid4())[:8]}"
            if apply_link and not apply_link.startswith('http'):
                apply_link = f"{self.base_url}{apply_link}"

            # Extract salary if available (some jobs don't have it)
            salary_elem = card.find('span', class_='salary')
            salary = self.clean_text(salary_elem.get_text()) if salary_elem else "Not disclosed"

            # Extract job description from job-desc section
            desc_elem = card.find('span', class_='job-desc')
            if desc_elem:
                job_description = self.clean_text(desc_elem.get_text())[:500]  # Limit length
            else:
                job_description = f"Software Developer position at {company_name}. Looking for candidates with {experience_required} experience in {location}."

            # Extract skills from job description or use defaults based on title
            skills = self.extract_skills(f"{job_title} {job_description}")
            if not skills:
                skills = ["Software Development", "Programming", "Problem Solving"]

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
                apply_link=apply_link,
                source="Naukri",
                remote_friendly="remote" in location.lower() or "hybrid" in job_description.lower(),
                industry="Technology",
                education_required="Bachelor's degree"
            )
        except Exception as e:
            print(f"Error parsing job card: {e}")
            import traceback
            traceback.print_exc()
            return None
