from fastapi import APIRouter, File, UploadFile, HTTPException
from typing import List, Optional
import re
from io import BytesIO
import threading

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


@router.post("/parse-resume")
async def parse_resume(file: UploadFile = File(...)):
    if not file.filename:
        raise HTTPException(status_code=400, detail="No file uploaded")

    content = await file.read()
    if not content:
        raise HTTPException(status_code=400, detail="Uploaded file is empty")

    text = None

    # Quick attempt: try to decode bytes to text
    try:
        text = content.decode("utf-8", errors="ignore")
    except Exception:
        text = None

    # If decode didn't yield useful text, try extracting from PDF if PyPDF2/pypdf available
    if not text or len(text.strip()) < 20:
        try:
            # import locally to avoid hard dependency at top-level
            try:
                from pypdf import PdfReader as _PdfReader
            except Exception:
                from PyPDF2 import PdfReader as _PdfReader  # type: ignore

            reader = _PdfReader(BytesIO(content))
            pages_text = []
            for p in reader.pages:
                try:
                    pages_text.append(p.extract_text() or "")
                except Exception:
                    # older PyPDF2 page structure
                    try:
                        pages_text.append(p.get_text() or "")
                    except Exception:
                        pages_text.append("")
            text = "\n".join(pages_text)
        except Exception:
            # final fallback: try latin1 decode
            try:
                text = content.decode("latin1", errors="ignore")
            except Exception:
                text = ""

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

    result = {
        "filename": file.filename,
        "size": len(content),
        "email": email,
        "phone": phone,
        "name": name,
        "skills": skills,
        "raw_text_snippet": (text or "")[:1000],
    }

    return result
