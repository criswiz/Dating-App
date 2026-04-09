from datetime import timedelta
from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from jose import JWTError, jwt

from app.schemas.user import UserCreate, UserOut, Token, LoginRequest, PasswordResetRequest, PasswordResetConfirm
from app.db.database import get_db
from app.services.auth import verify_password, create_access_token, get_password_hash
from app.services.user_service import get_user_by_email, create_user_with_profile
from app.services.deps import get_current_user
from app.services.rate_limit import SlidingWindowRateLimiter
from app.core.config import SECRET_KEY, ALGORITHM, REFRESH_TOKEN_EXPIRE_DAYS, AUTH_SIGNUP_RATE_LIMIT, AUTH_LOGIN_RATE_LIMIT
from app.models.user import User

import secrets
from datetime import datetime, timezone

router = APIRouter()

# Separate rate limiters for auth endpoints (limits configurable via env)
_login_limiter = SlidingWindowRateLimiter(max_requests=AUTH_LOGIN_RATE_LIMIT, window_seconds=60)
_signup_limiter = SlidingWindowRateLimiter(max_requests=AUTH_SIGNUP_RATE_LIMIT, window_seconds=60)


def _client_key(request: Request) -> str:
    forwarded = request.headers.get("X-Forwarded-For")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.client.host if request.client else "unknown"


@router.post("/signup", response_model=UserOut)
def signup(user_in: UserCreate, request: Request, db: Session = Depends(get_db)):
    if not _signup_limiter.allow(_client_key(request)):
        raise HTTPException(status_code=429, detail="Too many signup attempts. Try again later.")
    existing = get_user_by_email(db, user_in.email)
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")
    user = create_user_with_profile(
        db,
        email=user_in.email,
        password=user_in.password,
        name=user_in.name,
        bio=user_in.bio,
        age=user_in.age,
        gender=user_in.gender,
        intent=user_in.intent,
        city=user_in.city,
        interests=user_in.interests,
    )
    return user


@router.post("/login", response_model=Token)
def login(user_in: LoginRequest, request: Request, db: Session = Depends(get_db)):
    if not _login_limiter.allow(_client_key(request)):
        raise HTTPException(status_code=429, detail="Too many login attempts. Try again later.")
    user = get_user_by_email(db, user_in.email)
    if not user or not verify_password(user_in.password, user.hashed_password):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    if user.is_banned:
        raise HTTPException(status_code=403, detail="Account has been suspended")
    access_token = create_access_token({"sub": str(user.id)})
    refresh_token = create_access_token(
        {"sub": str(user.id), "type": "refresh"},
        expires_delta=timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS),
    )
    return {"access_token": access_token, "refresh_token": refresh_token, "token_type": "bearer"}


@router.post("/refresh", response_model=Token)
def refresh_token(payload: dict, db: Session = Depends(get_db)):
    token = payload.get("refresh_token")
    if not token:
        raise HTTPException(status_code=400, detail="refresh_token required")
    try:
        data = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        if data.get("type") != "refresh":
            raise HTTPException(status_code=400, detail="Invalid token type")
        user_id = data.get("sub")
        if not user_id:
            raise HTTPException(status_code=400, detail="Invalid token")
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid or expired refresh token")
    user = db.query(User).filter(User.id == int(user_id)).first()
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    if user.is_banned:
        raise HTTPException(status_code=403, detail="Account has been suspended")
    new_access = create_access_token({"sub": str(user.id)})
    new_refresh = create_access_token(
        {"sub": str(user.id), "type": "refresh"},
        expires_delta=timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS),
    )
    return {"access_token": new_access, "refresh_token": new_refresh, "token_type": "bearer"}


@router.get("/me", response_model=UserOut)
def get_me(current_user: User = Depends(get_current_user)):
    return current_user


@router.post("/forgot-password")
def forgot_password(payload: PasswordResetRequest, db: Session = Depends(get_db)):
    user = get_user_by_email(db, payload.email)
    # Always return 200 to avoid email enumeration
    if not user:
        return {"status": "ok", "message": "If that email is registered, a reset token will be provided."}
    token = secrets.token_urlsafe(32)
    user.reset_token = get_password_hash(token)
    user.reset_token_expires = datetime.now(timezone.utc).replace(tzinfo=None) + timedelta(hours=1)
    db.commit()
    # In production: send `token` via email. Returned here for dev/testing only.
    return {"status": "ok", "reset_token": token}


@router.post("/reset-password")
def reset_password(payload: PasswordResetConfirm, db: Session = Depends(get_db)):
    # Find user whose reset_token matches
    users = db.query(User).filter(User.reset_token.isnot(None)).all()
    matched_user = None
    for u in users:
        if u.reset_token and verify_password(payload.token, u.reset_token):
            matched_user = u
            break
    if not matched_user:
        raise HTTPException(status_code=400, detail="Invalid or expired reset token")
    now = datetime.now(timezone.utc).replace(tzinfo=None)
    if matched_user.reset_token_expires is None or matched_user.reset_token_expires < now:
        raise HTTPException(status_code=400, detail="Reset token has expired")
    if len(payload.new_password) < 8:
        raise HTTPException(status_code=400, detail="Password must be at least 8 characters")
    matched_user.hashed_password = get_password_hash(payload.new_password)
    matched_user.reset_token = None
    matched_user.reset_token_expires = None
    db.commit()
    return {"status": "ok", "message": "Password updated successfully"}
