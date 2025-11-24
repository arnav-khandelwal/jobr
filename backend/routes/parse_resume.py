from fastapi import APIRouter, File, UploadFile, HTTPException
from typing import List, Optional, Dict
import re
from io import BytesIO
import threading
import tempfile
import subprocess
import shutil
import os

# Lazy-loaded NLP model (spaCy) to avoid startup cost; thread-safe init
_nlp = None
_nlp_lock = threading.Lock()

router = APIRouter(prefix="/api", tags=["resume"])


def _extract_email(text: str):
    m = re.search(r"[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+", text)
    return m.group(0) if m else None


def _extract_phone(text: str):
    # Very permissive phone regex (international/local)
    m = re.search(r"(\+?\d{1,3}[\s-]?)?(?:\(?\d{2,4}\)?[\s-]?)?\d{6,10}", text)
    return m.group(0) if m else None


def _find_skills(text: str, keywords: List[str]):
    found = []
    lower = text.lower()
    for k in keywords:
        if k.lower() in lower:
            found.append(k)
    return found


def _load_nlp():
    global _nlp
    if _nlp is not None:
        return _nlp
    with _nlp_lock:
        if _nlp is not None:
            return _nlp
        try:
            import spacy  # type: ignore
            try:
                _nlp = spacy.load("en_core_web_sm")
            except Exception:
                # Attempt alternative small model name or raise; fallback to None
                try:
                    _nlp = spacy.load("en_core_web_md")
                except Exception:
                    _nlp = None
        except Exception:
            _nlp = None
    return _nlp


def _extract_name(text: str) -> Optional[str]:
    if not text:
        return None
    nlp = _load_nlp()
    if nlp:
        try:
            doc = nlp(text[:5000])  # examine first part only for speed
            # Prefer PERSON entities; choose longest token span
            persons = [ent.text.strip() for ent in doc.ents if ent.label_ == "PERSON"]
            if persons:
                # Heuristic: return the first with <=4 words and contains at least one space
                for p in persons:
                    if 2 <= len(p.split()) <= 4:
                        return p
                return persons[0]
        except Exception:
            pass
    # Fallback heuristic: first line with 2-3 capitalized words
    for line in text.splitlines():
        tokens = line.strip().split()
        if 2 <= len(tokens) <= 4:
            cap_words = [t for t in tokens if re.match(r"^[A-Z][a-zA-Z'-]+$", t)]
            if len(cap_words) >= 2:
                return " ".join(cap_words)
    return None


def _extract_sections(text: str) -> Dict[str, List[str]]:
    """Heuristically extract Education and Experience sections.
    Looks for heading lines (case-insensitive) and captures subsequent non-empty lines
    until a blank line followed by another heading or until a size cap.
    """
    lines = [l.rstrip() for l in text.splitlines()]
    headings_experience = {
        "professional experience",
        "experience",
        "work experience",
        "employment history",
    }
    headings_education = {"education", "academic", "academics"}
    # Unified heading detection set
    all_headings = headings_experience | headings_education | {
        "skills",
        "projects",
        "summary",
        "certifications",
        "languages",
    }

    def normalize(line: str) -> str:
        return re.sub(r"[^a-zA-Z ]", "", line).strip().lower()

    sections: Dict[str, List[str]] = {"education": [], "experience": []}
    current = None
    buffer: List[str] = []

    def commit():
        nonlocal buffer, current
        if current == "education" and buffer:
            sections["education"] = buffer[:20]
        elif current == "experience" and buffer:
            sections["experience"] = buffer[:30]
        buffer = []

    for raw in lines:
        norm = normalize(raw)
        if norm in all_headings:
            # New heading encountered – commit previous
            commit()
            if norm in headings_education:
                current = "education"
            elif norm in headings_experience:
                current = "experience"
            else:
                current = None
            continue
        # Capture lines if inside target section
        if current in {"education", "experience"}:
            if not raw.strip():
                # blank line – may indicate end of section; commit and reset
                commit()
                current = None
            else:
                cleaned = raw.strip()
                cleaned = re.sub(r"^[•\-\*\u2022]+\s*", "", cleaned)
                buffer.append(cleaned)
    # Final commit
    commit()
    return sections


@router.post("/parse-resume")
async def parse_resume(file: UploadFile = File(...)):
    if not file.filename:
        raise HTTPException(status_code=400, detail="No file uploaded")

    content = await file.read()
    if not content:
        raise HTTPException(status_code=400, detail="Uploaded file is empty")

    text = None  # <-- IMPORTANT: do NOT try utf-8 decode

    # Always use pdftotext first
    if shutil.which("pdftotext"):
        tmp_path = None
        try:
            with tempfile.NamedTemporaryFile(suffix=".pdf", delete=False) as tmpf:
                tmpf.write(content)
                tmpf.flush()
                tmp_path = tmpf.name

            cmds = [
                ["pdftotext", "-enc", "UTF-8", tmp_path, "-"],
                ["pdftotext", tmp_path, "-"],
            ]

            for cmd in cmds:
                try:
                    res = subprocess.run(
                        cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=20
                    )
                    if res.returncode == 0 and res.stdout:
                        text = res.stdout.decode("utf-8", errors="ignore")
                        break
                except:
                    continue

        finally:
            if tmp_path:
                try:
                    os.remove(tmp_path)
                except:
                    pass

    # If STILL nothing (rare), fallback
    if not text or len(text.strip()) < 20:
        raise HTTPException(400, "Failed to extract text")

    # Basic parsing heuristics
    email = _extract_email(text or "")
    phone = _extract_phone(text or "")
    name = _extract_name(text or "")

    # simple skills keyword scan
    keywords = [
        "Python",
        "Dart",
        "Flutter",
        "Java",
        "JavaScript",
        "React",
        "Node",
        "SQL",
        "MongoDB",
        "AWS",
        "Docker",
        "Kubernetes",
    ]
    skills = _find_skills(text or "", keywords)

    sections = _extract_sections(text or "")

    result = {
        "filename": file.filename,
        "size": len(content),
        "email": email,
        "phone": phone,
        "name": name,
        "skills": skills,
        "education": sections.get("education", []),
        "experience": sections.get("experience", []),
        "raw_text_snippet": (text or "")[:1000],
    }

    return result
