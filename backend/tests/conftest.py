import os

os.environ["DATABASE_URL"] = "sqlite:///./test.db"
os.environ["AUTH_SIGNUP_RATE_LIMIT"] = "1000"
os.environ["AUTH_LOGIN_RATE_LIMIT"] = "1000"

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.main import app
from app.db.database import Base, get_db


SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db


@pytest.fixture(autouse=True)
def reset_db():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    # Reset all in-memory rate limiters so tests don't interfere with each other
    from app.services.rate_limit import interaction_limiter
    from app.api.auth import _login_limiter, _signup_limiter
    interaction_limiter.reset()
    _login_limiter.reset()
    _signup_limiter.reset()
    yield


@pytest.fixture
def client():
    return TestClient(app)


def auth_headers(client: TestClient, email: str, password: str, role: str = "user", **profile):
    signup_payload = {"email": email, "password": password, **profile}
    client.post("/auth/signup", json=signup_payload)
    if role == "admin":
        db = TestingSessionLocal()
        try:
            from app.models.user import User
            user = db.query(User).filter(User.email == email).first()
            if user:
                user.role = "admin"
                db.commit()
        finally:
            db.close()
    login_resp = client.post("/auth/login", json={"email": email, "password": password})
    token = login_resp.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}
