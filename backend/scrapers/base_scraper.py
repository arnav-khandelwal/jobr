# backend/scrapers/base_scraper.py
import requests
from bs4 import BeautifulSoup
from fake_useragent import UserAgent
import time
import random
from abc import ABC, abstractmethod
from typing import List
from models.job import Job

class BaseScraper(ABC):
    def __init__(self):
        self.ua = UserAgent()
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': self.ua.random,
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
            'Accept-Encoding': 'gzip, deflate',
            'Connection': 'keep-alive',
        })
    
    def get_page(self, url: str, retries: int = 3) -> BeautifulSoup:
        """Fetch and parse a web page with retry logic"""
        for attempt in range(retries):
            try:
                time.sleep(random.uniform(1, 3))
                response = self.session.get(url, timeout=40)
                response.raise_for_status()
                return BeautifulSoup(response.content, 'html.parser')
            except Exception as e:
                print(f"Attempt {attempt + 1} failed for {url}: {str(e)}")
                if attempt == retries - 1:
                    raise e
                time.sleep(random.uniform(2, 5))
    
    @abstractmethod
    def scrape_jobs(self, search_term: str, location: str, pages: int = 3) -> List[Job]:
        pass
    
    def clean_text(self, text: str) -> str:
        if not text:
            return ""
        return ' '.join(text.strip().split())
    
    def extract_skills(self, description: str) -> List[str]:
        common_skills = [
            'Python', 'Java', 'JavaScript', 'React', 'Node.js', 'Angular', 'Vue.js',
            'Flutter', 'Dart', 'Swift', 'Kotlin', 'PHP', 'Laravel', 'Django',
            'Flask', 'SQL', 'MongoDB', 'PostgreSQL', 'MySQL', 'Redis', 'Docker',
            'Kubernetes', 'AWS', 'Azure', 'GCP', 'Git', 'HTML', 'CSS', 'Figma',
            'Adobe XD', 'Photoshop', 'Machine Learning', 'AI', 'TensorFlow',
            'PyTorch', 'Data Science', 'Analytics', 'Tableau', 'Power BI'
        ]
        
        found_skills = []
        description_lower = description.lower()
        
        for skill in common_skills:
            if skill.lower() in description_lower:
                found_skills.append(skill)
        
        return found_skills[:5]