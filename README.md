# swipe_app — concise README

Single-repo mobile + backend app to discover jobs, swipe, upload/parse resumes and save user actions.

Quick project layout
- backend/ — FastAPI backend (MongoDB, resume parsing, auth, scrapers)
- lib/ — Flutter app (screens, services, resume upload, auth)
- assets/ etc. — app assets and widgets

Core features
- Email/password signup & signin (JWT)
- Resume upload & parsing (POST /api/parse-resume)
- Scrapers aggregate jobs (Naukri, RemoteOnly, …)
- Persisted cache & viewed/swiped job tracking
- Resume parsed data stored per user
- Bottom navigation: Track, Resume, Settings (and Home/Standouts)

Backend quickstart
1. Create & activate a venv:
   python -m venv venv
   source venv/bin/activate
2. Install deps:
   pip install -r backend/requirements.txt
3. Environment vars (.env or export):
   MONGO_URI=mongodb://localhost:27017
   MONGO_DB_NAME=jobr_db
   JWT_SECRET=change_this_long_random_secret
4. (If using spaCy NER) download model:
   python -m spacy download en_core_web_sm
5. Run:
   cd backend
   uvicorn main:app --reload --port 8000
6. Test parse endpoint:
   curl -F "file=@/path/resume.pdf" http://localhost:8000/api/parse-resume

Frontend quickstart (Flutter)
1. Ensure Flutter SDK installed.
2. Update packages and clean:
   flutter pub get
   flutter pub upgrade
   flutter clean
3. If using Android emulator, backend host is auto-detected (10.0.2.2). For iOS/simulator use localhost.
4. Run:
   flutter run

Notes & gotchas
- file_picker plugin: project pins a version compatible with the new Android embedding; run flutter pub upgrade and flutter clean if you hit build errors.
- Bcrypt had a 72-byte limit historically — backend uses Argon2 now; ensure backend requirements installed.
- MongoDB is the primary DB (use motor/mongo URI in env).
- Resume files can be stored in S3 or GridFS; metadata + parsed JSON live in MongoDB.
- API expects multipart file upload (curl uses `-F "file=@/path/resume.pdf"`).

Important endpoints
- POST /api/auth/signup — signup
- POST /api/auth/signin — signin (OAuth2 form)
- GET /api/auth/me — current user
- POST /api/parse-resume — multipart file -> parsed JSON
- GET /api/jobs — aggregated jobs (params vary)

Development tips
- Use uvicorn CLI for autoreload during backend work.
- Use flutter hot reload for UI tweaks.
- Create required Mongo indexes at backend startup (users.email unique, jobs source+source_id unique).

Where to extend
- Add refresh tokens / session revocation
- Add S3 file storage & signed URLs
- Improve parser (more NER models, resume section extraction)
- Add analytics pipeline / worker queue for heavy parsing

License & contact
- Add license file as needed.
- Repo owner/developer: refer to workspace project files for author info.
