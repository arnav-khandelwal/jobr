#!/usr/bin/env python3
"""
Test script for Naukri scraper
Run this to test if the scraper works before starting the API
"""

from scrapers.naukri_scraper import NaukriScraper

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
