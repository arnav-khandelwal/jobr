# backend/scrapers/indeed_scraper.py
from scrapers.base_scraper import BaseScraper
from models.job import Job
from typing import List
import uuid
import time
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from bs4 import BeautifulSoup

class IndeedScraper(BaseScraper):
    def __init__(self):
        super().__init__()
        self.base_url = "https://in.indeed.com"

    def scrape_jobs(self, search_term: str = "software developer", location: str = "India", pages: int = 1) -> List[Job]:
        jobs = []
        chrome_options = Options()
        # chrome_options.add_argument("--headless")  # Disable headless for debugging
        chrome_options.add_argument("--disable-blink-features=AutomationControlled")
        chrome_options.add_argument(
            "user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        )
        chrome_options.add_experimental_option("excludeSwitches", ["enable-automation"])
        chrome_options.add_experimental_option('useAutomationExtension', False)
        chrome_options.add_argument("--disable-gpu")
        chrome_options.add_argument("--no-sandbox")
        chrome_options.add_argument("--window-size=1920,1080")
        # Add more stealth options
        chrome_options.add_argument("--disable-extensions")
        chrome_options.add_argument("--disable-plugins")
        chrome_options.add_argument("--disable-images")  # Speed up loading
        chrome_options.add_argument("--disable-javascript")  # Wait, don't do this - we need JS

        driver = webdriver.Chrome(options=chrome_options)

        # Make Selenium less detectable
        driver.execute_cdp_cmd("Page.addScriptToEvaluateOnNewDocument", {
            "source": """
                Object.defineProperty(navigator, 'webdriver', {get: () => undefined})
            """
        })

        for page in range(pages):
            start = page * 10
            url = f"{self.base_url}/jobs?q={search_term}&l={location}&start={start}"
            print("Scraping URL:", url)
            driver.get(url)

            # Wait a bit before checking
            time.sleep(3)

            try:
                wait = WebDriverWait(driver, 15)
                # Try multiple selectors for job cards
                job_selectors = [
                    (By.ID, "mosaic-provider-jobcards"),
                    (By.CLASS_NAME, "job_seen_beacon"),
                    (By.CSS_SELECTOR, "[data-jk]"),
                ]

                container = None
                for selector_type, selector_value in job_selectors:
                    try:
                        container = wait.until(EC.presence_of_element_located((selector_type, selector_value)))
                        break
                    except:
                        continue

                if not container:
                    print(f"No job container found on page {page}")
                    continue

                # Scroll slowly to load all jobs
                for i in range(3):
                    driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
                    time.sleep(1)

                print("Job cards container HTML preview:\n", container.get_attribute("outerHTML")[:500])

            except Exception as e:
                print(f"Error loading page {page}: {e}")
                continue

            soup = BeautifulSoup(driver.page_source, "html.parser")

            # Try multiple ways to find job cards
            job_card_divs = []
            job_card_divs.extend(soup.find_all('div', class_='job_seen_beacon'))
            job_card_divs.extend(soup.find_all('div', {'data-jk': True}))
            job_card_divs.extend(soup.find_all('a', {'data-jk': True}))

            if not job_card_divs:
                print(f"No job cards found in parsed HTML on page {page}")
                continue

            print(f"Found {len(job_card_divs)} job cards on page {page}")

            for card in job_card_divs[:10]:  # Limit to 10 per page
                job = self._parse_job_card(card)
                if job:
                    jobs.append(job)

            time.sleep(3)  # Longer delay between pages

        driver.quit()
        return jobs

    def _parse_job_card(self, card) -> Job:
        # Try multiple selectors for each field
        title_elem = (
            card.find('h2', class_='jobTitle') or
            card.find('a', {'data-jk': True}) or
            card.find('span', title=True)
        )

        company_elem = (
            card.find('span', class_='companyName') or
            card.find('span', class_='company')
        )

        location_elem = (
            card.find('div', class_='companyLocation') or
            card.find('span', class_='location')
        )

        summary_elem = (
            card.find('div', class_='job-snippet') or
            card.find('div', class_='summary')
        )

        link_elem = title_elem.find('a') if title_elem and hasattr(title_elem, 'find') else title_elem if title_elem and title_elem.name == 'a' else None

        job_title = self.clean_text(title_elem.get_text()) if title_elem else None
        company_name = self.clean_text(company_elem.get_text()) if company_elem else None
        location = self.clean_text(location_elem.get_text()) if location_elem else None
        job_description = self.clean_text(summary_elem.get_text()) if summary_elem else None
        apply_link = f"{self.base_url}{link_elem['href']}" if link_elem and link_elem.get('href') else None

        if not job_title or not company_name or not location:
            return None

        return Job(
            job_id=str(uuid.uuid4()),
            job_title=job_title,
            company_name=company_name,
            location=location,
            job_type="Full-time",
            salary="Not disclosed",
            experience_required="Not specified",
            skills=self.extract_skills(job_description or ""),
            job_description=job_description[:90] if job_description else "",
            posted_date="Recently",
            apply_link=apply_link or "",
            source="Indeed",
            remote_friendly="remote" in (location or "").lower(),
            industry=None,
            education_required=None
        )