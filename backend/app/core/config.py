import os
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./dev.db")
SECRET_KEY = os.getenv("SECRET_KEY", "super-secret-change-me")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60"))
REFRESH_TOKEN_EXPIRE_DAYS = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS", "30"))
ALGORITHM = "HS256"
CORS_ALLOW_ORIGINS = [
    origin.strip()
    for origin in os.getenv(
        "CORS_ALLOW_ORIGINS",
        "http://localhost:8000,http://localhost:3000",
    ).split(",")
    if origin.strip()
]

BASE_URL = os.getenv("BASE_URL", "http://localhost:8000")
UPLOADS_DIR = os.getenv("UPLOADS_DIR", "uploads")

AUTH_SIGNUP_RATE_LIMIT = int(os.getenv("AUTH_SIGNUP_RATE_LIMIT", "5"))
AUTH_LOGIN_RATE_LIMIT = int(os.getenv("AUTH_LOGIN_RATE_LIMIT", "10"))


def _as_bool(value: str | None, default: bool = False) -> bool:
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


AI_FEATURES_ENABLED = _as_bool(os.getenv("AI_FEATURES_ENABLED", "false"))
AI_GATE_APPROVED = _as_bool(os.getenv("AI_GATE_APPROVED", "false"))
AI_MIN_MONTHLY_REVENUE = int(os.getenv("AI_MIN_MONTHLY_REVENUE", "2000"))
AI_MIN_TRAINING_EVENTS = int(os.getenv("AI_MIN_TRAINING_EVENTS", "10000"))
