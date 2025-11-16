#!/usr/bin/env python3
"""
Test script for scrapers
Run this to test if the scrapers work before starting the API
"""

from scrapers.naukri_scraper import NaukriScraper
from scrapers.remoteonly_scraper import RemoteOnlyScraper

def test_naukri_scraper():
    print("Testing Naukri Scraper...")
    scraper = NaukriScraper()

    try:
        jobs = scraper.scrape_jobs("software developer", "bangalore", 1)
        print(f"Successfully scraped {len(jobs)} jobs!")

        if jobs:
            print("\nFirst job details:")
            job = jobs[0]
            print(f"Title: {job.job_title}")
            print(f"Company: {job.company_name}")
            print(f"Location: {job.location}")
            print(f"Experience: {job.experience_required}")
            print(f"Salary: {job.salary}")
        else:
            print("No jobs found - check the scraper")

    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    test_naukri_scraper()
    print("\nTesting RemoteOnly Scraper...")
    ro = RemoteOnlyScraper()
    try:
        jobs = ro.scrape_jobs("software", "remote", 1)
        print(f"RemoteOnly: scraped {len(jobs)} jobs")
        if jobs:
            j = jobs[0]
            print(f"Title: {j.job_title}")
            print(f"Company: {j.company_name}")
            print(f"Location: {j.location}")
            print(f"Salary: {j.salary}")
            print(f"Type: {j.job_type}")
            print(f"Apply: {j.apply_link}")
    except Exception as e:
        print(f"RemoteOnly error: {e}")
