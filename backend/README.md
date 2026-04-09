Dating App - Backend (FastAPI)

Quickstart

1. Create a virtualenv and install dependencies:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

2. Create `.env` in the `backend/` folder. Example values (see `.env.example`):

```
DATABASE_URL=sqlite:///./dev.db
SECRET_KEY=super-secret-change-me
ACCESS_TOKEN_EXPIRE_MINUTES=60
```

3. Run the app locally:

```bash
alembic upgrade head
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

Database migrations

- Create a new migration after model changes:

```bash
alembic revision --autogenerate -m "describe change"
```

- Apply migrations:

```bash
alembic upgrade head
```

- Roll back one revision:

```bash
alembic downgrade -1
```

What is here
- `app/main.py` - FastAPI application entry
- `app/api` - routers (auth, profiles, etc.)
- `app/models` - SQLAlchemy models
- `app/schemas` - Pydantic request/response models
- `app/db` - database session and utils
- `app/services` - auth utilities (JWT, hashing)

Next steps
- Add image upload (S3 or local), media processing
- Implement matching and swipe endpoint
- Add tests and CI
