from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api import auth, profiles
from app.db.database import engine, Base

# create DB tables (for quickstart - replace with Alembic for production)
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Dating App API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:8000", "http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/auth", tags=["auth"])
app.include_router(profiles.router, prefix="/profiles", tags=["profiles"])

@app.get("/")
def root():
    return {"status": "ok", "message": "Dating App API"}
