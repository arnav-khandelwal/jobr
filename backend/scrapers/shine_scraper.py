"""
Selenium-based scraper for shine.com homepage Domain Jobs carousels.

Parses cards with classes like:
 - div.jobCard_jobCard__jjUmu (root card)
 - strong.jobCard_pReplaceH2__xWmHg a (title + href)
 - div.jobCard_jobCard_cName__mYnow span (company)
 - div.jobCard_jobCard_features__wJid6 span (posted date)
 - div.jobCard_locationIcon__zrWt2 (location)
 - div.jobCard_jobIcon__3FB1t (experience)
 - ul.jobCard_jobCard_jobDetail__jD82J li (misc chips; not skills)

Shows a visible browser window to demonstrate real scraping.
"""

from __future__ import annotations
from typing import List, Optional
from datetime import datetime
import time
import uuid

from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

from scrapers.base_scraper import BaseScraper
from models.job import Job


class ShineScraper(BaseScraper):
    def __init__(self):
        super().__init__()
        self.base_url = "https://www.shine.com"

    def scrape_jobs(self, search_term: str = "", location: str = "India", pages: int = 1) -> List[Job]:
        jobs: List[Job] = []

        chrome_options = Options()
        # Keep non-headless to show browser activity
        # chrome_options.add_argument("--headless")
        chrome_options.add_argument("--disable-gpu")
        chrome_options.add_argument("--no-sandbox")
        chrome_options.add_argument("--window-size=1400,900")
        chrome_options.add_argument(
            "--user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        )

        driver = webdriver.Chrome(options=chrome_options)
        try:
            driver.get(self.base_url)
            # Wait for Domain Jobs section to appear
            WebDriverWait(driver, 15).until(
                EC.presence_of_element_located((By.CSS_SELECTOR, ".domainjobs_card_container__eJMdE"))
            )
            time.sleep(1.5)  # Allow slick sliders to initialize

            # Ensure we are on IT domain tab specifically (only IT jobs)
            try:
                tabs = driver.find_elements(By.CSS_SELECTOR, "ul.domainjobs_domainJobs___Zi5l li")
                for t in tabs:
                    label = (t.text or "").strip().lower()
                    if label == "it":
                        t.click()
                        time.sleep(0.8)
                        break
            except Exception:
                pass

            soup = BeautifulSoup(driver.page_source, "html.parser")

            # Limit to the active IT tab panel content
            containers = soup.select(
                "div.domainjobs_tab_panel_content__FSMD0.domainjobs_active_content__ZqqrZ .domainjobs_card_container__eJMdE"
            )
            cards = []
            for c in containers:
                cards.extend(c.select("div.jobCard_jobCard__jjUmu"))

            if not cards:
                # Fallback: search globally
                cards = soup.select("div.jobCard_jobCard__jjUmu")

            for card in cards:
                job = self._parse_card(card)
                if job:
                    jobs.append(job)

        except Exception as e:
            print(f"Shine scraping error: {e}")
        finally:
            # time.sleep(2)  # keep window visible briefly if debugging
            driver.quit()

        return jobs

    def _parse_card(self, card) -> Optional[Job]:
        try:
            # Title and link
            title_anchor = card.select_one("strong.jobCard_pReplaceH2__xWmHg a")
            job_title = self.clean_text(title_anchor.get_text()) if title_anchor else None

            # Company
            company_span = card.select_one("div.jobCard_jobCard_cName__mYnow span")
            company_name = self.clean_text(company_span.get_text()) if company_span else "Unknown"

            # Posted date
            posted_span = card.select_one("div.jobCard_jobCard_features__wJid6 span")
            posted_date = self.clean_text(posted_span.get_text()) if posted_span else "Recently"

            # Location and experience
            loc_div = card.select_one("div.jobCard_locationIcon__zrWt2")
            location = self.clean_text(loc_div.get_text()) if loc_div else "India"
            # Remove "+N" suffix artifacts like "+ 2" etc.
            if "+" in location:
                location = location.split("+")[0].strip()

            exp_div = card.select_one("div.jobCard_jobIcon__3FB1t")
            experience_required = self.clean_text(exp_div.get_text()) if exp_div else "Not specified"

            # Apply link (prefer meta itemprop url; else title anchor href)
            meta_url = card.select_one('meta[itemprop="url"]')
            apply_link = meta_url.get("content") if meta_url and meta_url.get("content") else None
            if not apply_link:
                href = title_anchor.get("href") if title_anchor else None
                if href:
                    apply_link = href if href.startswith("http") else f"{self.base_url}{href}"
            if not apply_link:
                apply_link = self.base_url

            # Salary (rare in these cards)
            salary = "Not disclosed"
            # Chips list isn't skills; synthesize skills via heuristics
            description = f"{job_title or ''} at {company_name} in {location}. Experience: {experience_required}."
            skills = self.extract_skills(description)

            if not job_title:
                return None

            return Job(
                job_id=str(uuid.uuid4()),
                job_title=job_title,
                company_name=company_name,
                location=location,
                job_type="Full-time",
                salary=salary,
                experience_required=experience_required,
                skills=skills[:5],
                job_description=description[:250],
                posted_date=posted_date,
                apply_link=apply_link,
                source="Shine",
                remote_friendly="remote" in location.lower(),
                company_logo_url=None,
                industry=None,
                education_required=None,
                scraped_at=datetime.now(),
            )
        except Exception as e:
            print(f"Error parsing Shine card: {e}")
            return None


# Convenience wrapper

def scrape_shine(search_term: str = "", location: str = "India", pages: int = 1) -> List[Job]:
    return ShineScraper().scrape_jobs(search_term, location, pages)
