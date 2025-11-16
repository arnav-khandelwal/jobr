"""
Selenium-based scraper for remoteonly.io job listings.

- Opens a visible Chrome window (non-headless)
- Scrolls the listings page to load as many jobs as available
- Parses each card and extracts core fields
- Does not filter by search term (returns all available jobs on the page)
"""

from typing import List, Set
from urllib.parse import urljoin
from datetime import datetime
import uuid
import time

from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.chrome.options import Options

from scrapers.base_scraper import BaseScraper
from models.job import Job


class RemoteOnlyScraper(BaseScraper):
    def __init__(self):
        super().__init__()
        self.base_url = "https://remoteonly.io"

    def scrape_jobs(self, search_term: str = "", location: str = "remote", pages: int = 1) -> List[Job]:
        jobs: List[Job] = []

        list_url = urljoin(self.base_url, "/remote-jobs")

        chrome_options = Options()
        # IMPORTANT: Do NOT enable headless; we want to show the browser window
        # chrome_options.add_argument("--headless")  # leave commented to display browser
        chrome_options.add_argument("--disable-gpu")
        chrome_options.add_argument("--no-sandbox")
        chrome_options.add_argument("--window-size=1280,900")
        chrome_options.add_argument(
            "--user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        )

        driver = webdriver.Chrome(options=chrome_options)
        try:
            driver.get(list_url)
            time.sleep(3)

            # Attempt to scroll to load more jobs (if lazy-loaded)
            last_height = driver.execute_script("return document.body.scrollHeight")
            max_scrolls = 8
            for _ in range(max_scrolls):
                driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
                time.sleep(1.5)
                new_height = driver.execute_script("return document.body.scrollHeight")
                if new_height == last_height:
                    break
                last_height = new_height

            soup = BeautifulSoup(driver.page_source, "html.parser")

            anchors = soup.select('a[aria-label][href^="/remote-jobs/"]')
            seen_hrefs: Set[str] = set()
            print(f"[RemoteOnly] Found {len(anchors)} job anchors")

            for a in anchors:
                href = a.get("href") or ""
                if not href or href in seen_hrefs:
                    continue
                seen_hrefs.add(href)

                card = self._find_card_root(a)
                job = self._parse_job_card(card, a)
                if job:
                    jobs.append(job)

        except Exception as e:
            print(f"RemoteOnly scraping error: {e}")
        finally:
            # Keep the window a moment for visibility if run interactively
            # Comment the next sleep if not desired
            # time.sleep(2)
            driver.quit()

        return jobs

    def _find_card_root(self, anchor):
        node = anchor
        for _ in range(8):
            if not node:
                break
            classes = node.get("class") or []
            if any(k in classes for k in ["shadow-sm", "rounded-lg", "border", "bg-card"]):
                return node
            node = node.parent
        return anchor.parent if anchor else None

    def _parse_job_card(self, card, link_anchor) -> Job | None:
        try:
            title_elem = card.find("h3") if card else None
            job_title = self.clean_text(title_elem.get_text()) if title_elem else None
            if not job_title:
                aria = link_anchor.get("aria-label") if link_anchor else None
                if aria and ":" in aria:
                    job_title = self.clean_text(aria.split(":", 1)[1])

            company_elem = title_elem.find_next("p") if title_elem else (card.find("p") if card else None)
            company_name = self.clean_text(company_elem.get_text()) if company_elem else "Unknown"

            time_elem = card.find("time") if card else None
            posted_date = self.clean_text(time_elem.get_text()) if time_elem else "Recently"

            chips = card.select("div.inline-flex") if card else []
            salary = "Not disclosed"
            job_type = "Full-time"
            location = "Remote"
            tags: List[str] = []
            for ch in chips:
                text = self.clean_text(ch.get_text())
                if not text:
                    continue
                if text.startswith("💰"):
                    salary = text.replace("💰", "").strip()
                elif text.startswith("🕐"):
                    job_type = text.replace("🕐", "").strip()
                elif text.startswith("🌍"):
                    location = text.replace("🌍", "").strip() or "Remote"
                else:
                    if len(text) <= 32 and all(c.isalnum() or c in " .+#-" for c in text):
                        tags.append(text)

            href = link_anchor.get("href") if link_anchor else None
            apply_link = urljoin(self.base_url, href) if href else self.base_url

            job_description = f"{job_title or 'Remote Role'} at {company_name}. Remote role."

            skills = list(dict.fromkeys(tags))
            if not skills:
                skills = self.extract_skills(f"{job_title} {job_description}")

            return Job(
                job_id=str(uuid.uuid4()),
                job_title=job_title or "Remote Role",
                company_name=company_name,
                location=location or "Remote",
                job_type=job_type or "Full-time",
                salary=salary or "Not disclosed",
                experience_required="Not specified",
                skills=skills[:5],
                job_description=job_description,
                posted_date=posted_date,
                apply_link=apply_link,
                source="RemoteOnly",
                remote_friendly=True,
                company_logo_url=None,
                industry=None,
                education_required=None,
                scraped_at=datetime.now(),
            )
        except Exception as e:
            print(f"Error parsing RemoteOnly card: {e}")
            return None
