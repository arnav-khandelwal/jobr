#!/usr/bin/env python
# backend/scrapers/placementindia_scraper.py
"""Scraper for placementindia.com job listings.

Structure similar to `naukri_scraper.py`:
 - Class with `scrape_jobs` (search_term, location, pages)
 - Internal `_parse_job_card` helper
 - Returns list[Job]

Site markup (sample):
<div class="sjc-list">
    <div class="sjc-iteam pr_list" data-url="JOB_URL"> ... </div>

Fields inside each card:
    h2.sjci-heading > a.job-name (title), p.job-cname (company)
    ul.sjci-need li for experience, salary, location
    div.sjci-skils div.sk_list span for skills

Uses requests + BeautifulSoup only (no Selenium) for performance.
"""

from typing import List, Optional
from bs4 import BeautifulSoup
import uuid
import sys, os, time
from selenium import webdriver
from selenium.webdriver.chrome.options import Options

# Allow running as a standalone script: python scrapers/placementindia_scraper.py
if __name__ == "__main__" and __package__ is None:  # executed directly, not as module
        # Add project root (parent of scrapers/) to sys.path so absolute imports work
        sys.path.append(os.path.dirname(os.path.dirname(__file__)))

from scrapers.base_scraper import BaseScraper  # type: ignore
from models.job import Job  # type: ignore

class PlacementIndiaScraper(BaseScraper):
    def __init__(self):
        super().__init__()
        self.base_url = "https://www.placementindia.com"
        # A generic fresher jobs page; can be adapted to search queries later.
        self.default_listing_path = ""

    def build_url(self, search_term: str, location: str, page: int) -> str:
        # PlacementIndia has various URL patterns; for now ignore search_term/location.
        # Future enhancement: map search_term to slug: e.g. "software-developer" -> "/jobs/software-developer-jobs.htm"
        # Page handling: site may use ?page=2 or numeric path segments; keep simple until verified.
        base = f"{self.base_url}{self.default_listing_path}"
        if page > 1:
            return f"{base}?page={page}"
        return base

    def scrape_jobs(self, search_term: str = "software developer", location: str = "India", pages: int = 1, show_browser: bool = True) -> List[Job]:
        """Scrape PlacementIndia fresher jobs. If show_browser=True a visible Chrome window is used.
        Falls back to requests if Selenium initialization fails."""
        jobs: List[Job] = []
        driver = None
        if show_browser:
            try:
                chrome_options = Options()
                # DO NOT add headless flag so evaluator sees browser
                chrome_options.add_argument("--window-size=1400,900")
                chrome_options.add_argument("--disable-gpu")
                chrome_options.add_argument("--no-sandbox")
                chrome_options.add_argument("--user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
                driver = webdriver.Chrome(options=chrome_options)
            except Exception as e:
                print(f"Selenium init failed ({e}); falling back to requests mode.")
                driver = None

        for page in range(1, pages + 1):
            url = self.build_url(search_term, location, page)
            print(f"Scraping PlacementIndia page {page}: {url}")
            if driver:
                try:
                    driver.get(url)
                    time.sleep(4)  # allow dynamic content
                    html = driver.page_source
                    soup = BeautifulSoup(html, 'html.parser')
                except Exception as e:
                    print(f"Selenium error fetching page {page}: {e}")
                    continue
            else:
                try:
                    soup = self.get_page(url)
                except Exception as e:
                    print(f"Requests error fetching page {page}: {e}")
                    continue

            listing_container = soup.find('div', class_='sjc-list') or soup
            cards = listing_container.find_all('div', class_='sjc-iteam')
            if not cards:
                print(f"No job cards found on page {page}")
                continue

            for card in cards:
                job = self._parse_job_card(card)
                if job:
                    jobs.append(job)

            # Friendly pacing between pages when using requests only
            if not driver:
                time.sleep(2)

        if driver:
            try:
                driver.quit()
            except Exception:
                pass
        return jobs

    def _parse_job_card(self, card) -> Optional[Job]:
        try:
            data_url = card.get('data-url')
            inner = card.find('div', class_='sjci') or card
            heading = inner.find('h2', class_='sjci-heading')
            title_elem = heading.find('a', class_='job-name') if heading else None
            company_elem = heading.find('p', class_='job-cname') if heading else None

            job_title = self.clean_text(title_elem.get_text()) if title_elem else None
            company_name = self.clean_text(company_elem.get_text()) if company_elem else None

            need_list = inner.find('ul', class_='sjci-need')
            exp = salary = location = ""
            if need_list:
                li_elems = need_list.find_all('li')
                for li in li_elems:
                    text = self.clean_text(li.get_text())
                    if 'Lac' in text or 'yr' in text.lower() or 'lac/yr' in text.lower():
                        salary = text
                    elif ('Fresher' in text) or ('yrs' in text) or ('yr' in text.lower()):
                        exp = text
                    else:
                        # treat as location if span exists
                        if li.find('span'):
                            location = self.clean_text(li.find('span').get_text())
                        else:
                            # fallback: if text contains spaces and no digits treat as location
                            if not any(ch.isdigit() for ch in text):
                                location = text

            skills_block = inner.find('div', class_='sjci-skils')
            skills_list = []
            if skills_block:
                for span in skills_block.find_all('span'):
                    skill_text = self.clean_text(span.get_text())
                    if skill_text:
                        skills_list.append(skill_text)
            # Deduplicate & limit
            skills_list = list(dict.fromkeys(skills_list))[:12]

            if not job_title or not company_name:
                return None

            apply_link = data_url or (title_elem['href'] if title_elem and title_elem.get('href') else '')
            if apply_link and apply_link.startswith('/'):
                apply_link = f"{self.base_url}{apply_link}"

            # Basic description synthesis
            desc_parts = [job_title, company_name]
            if location:
                desc_parts.append(location)
            if exp:
                desc_parts.append(f"Exp: {exp}")
            if salary:
                desc_parts.append(f"Salary: {salary}")
            job_description = ' | '.join([p for p in desc_parts if p])

            return Job(
                job_id=str(uuid.uuid4()),
                job_title=job_title,
                company_name=company_name,
                location=location or "India",
                job_type="Full-time",  # Not explicitly available
                salary=salary or "Not disclosed",
                experience_required=exp or "Not specified",
                skills=skills_list or self.extract_skills(job_description),
                job_description=job_description[:180],
                posted_date="Recently",  # Site markup did not show explicit date in sample
                apply_link=apply_link,
                source="PlacementIndia",
                remote_friendly="remote" in (location or '').lower(),
                industry=None,
                education_required=None
            )
        except Exception as e:
            print(f"Error parsing PlacementIndia card: {e}")
            return None

# Convenience helper
def scrape_placementindia(search_term: str = 'software developer', location: str = 'India', pages: int = 1, show_browser: bool = True) -> List[Job]:
    """Convenience wrapper used elsewhere."""
    return PlacementIndiaScraper().scrape_jobs(search_term, location, pages, show_browser=show_browser)

if __name__ == "__main__":
    # Simple manual run for quick verification
    scraper = PlacementIndiaScraper()
    sample_jobs = scraper.scrape_jobs(pages=1, show_browser=True)
    print(f"Scraped {len(sample_jobs)} PlacementIndia jobs")
    if sample_jobs:
        from pprint import pprint
        pprint(sample_jobs[0].model_dump())
