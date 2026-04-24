import os
import uuid
from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.models.user import User
from app.models.social import Interaction, UserBlock
from app.schemas.user import UserOut, ProfileUpdate
from app.schemas.social import DiscoveryCandidate
from app.services.deps import get_current_user
from app.services.matching import compatibility_score
from app.core.config import UPLOADS_DIR, BASE_URL

ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/webp"}
MAX_PHOTO_SIZE_BYTES = 5 * 1024 * 1024  # 5 MB

router = APIRouter()


@router.get("/", response_model=list[UserOut])
def list_profiles(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    users = db.query(User).filter(User.id != current_user.id).all()
    return users


@router.get("/me", response_model=UserOut)
def get_my_profile(current_user: User = Depends(get_current_user)):
    return current_user


@router.patch("/me", response_model=UserOut)
def update_my_profile(
    payload: ProfileUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    update_data = payload.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(current_user, field, value)
    db.commit()
    db.refresh(current_user)
    return current_user


@router.post("/me/photo", response_model=UserOut)
async def upload_photo(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if file.content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(status_code=400, detail="Only JPEG, PNG, and WebP images are allowed")

    contents = await file.read()
    if len(contents) > MAX_PHOTO_SIZE_BYTES:
        raise HTTPException(status_code=400, detail="Image must be 5 MB or smaller")

    os.makedirs(UPLOADS_DIR, exist_ok=True)
    ext = file.filename.rsplit(".", 1)[-1] if file.filename and "." in file.filename else "jpg"
    filename = f"{uuid.uuid4().hex}.{ext}"
    filepath = os.path.join(UPLOADS_DIR, filename)

    with open(filepath, "wb") as f:
        f.write(contents)

    current_user.photo_url = f"{BASE_URL}/static/uploads/{filename}"
    db.commit()
    db.refresh(current_user)
    return current_user


@router.get("/discover", response_model=list[DiscoveryCandidate])
def discover_profiles(
    limit: int = Query(default=20, ge=1, le=100),
    min_age: int | None = Query(default=None, ge=18),
    max_age: int | None = Query(default=None, ge=18),
    intent: str | None = Query(default=None),
    tribe: str | None = Query(default=None),
    religion: str | None = Query(default=None),
    relationship_status: str | None = Query(default=None),
    has_kids: str | None = Query(default=None),
    search: str | None = Query(default=None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if min_age is not None and max_age is not None and min_age > max_age:
        raise HTTPException(status_code=400, detail="min_age cannot be greater than max_age")
    candidates_query = db.query(User).filter(User.id != current_user.id, User.is_banned.is_(False))
    if min_age is not None:
        candidates_query = candidates_query.filter(User.age >= min_age)
    if max_age is not None:
        candidates_query = candidates_query.filter(User.age <= max_age)
    if intent:
        candidates_query = candidates_query.filter(User.intent == intent)
    if tribe:
        candidates_query = candidates_query.filter(User.tribe.ilike(f"%{tribe}%"))
    if religion:
        candidates_query = candidates_query.filter(User.religion == religion)
    if relationship_status:
        candidates_query = candidates_query.filter(User.relationship_status == relationship_status)
    if has_kids:
        candidates_query = candidates_query.filter(User.has_kids == has_kids)
    if search:
        term = f"%{search}%"
        candidates_query = candidates_query.filter(
            User.name.ilike(term) | User.city.ilike(term) | User.bio.ilike(term) | User.occupation.ilike(term)
        )

    interacted_ids = {
        row[0]
        for row in db.query(Interaction.target_user_id).filter(Interaction.actor_user_id == current_user.id).all()
    }
    blocked_ids = {
        row[0]
        for row in db.query(UserBlock.blocked_user_id).filter(UserBlock.blocker_user_id == current_user.id).all()
    }
    blocked_by_ids = {
        row[0]
        for row in db.query(UserBlock.blocker_user_id).filter(UserBlock.blocked_user_id == current_user.id).all()
    }
    excluded = interacted_ids.union(blocked_ids).union(blocked_by_ids)

    ranked: list[DiscoveryCandidate] = []
    for candidate in candidates_query.all():
        if candidate.id in excluded:
            continue
        ranked.append(
            DiscoveryCandidate(
                id=candidate.id,
                email=candidate.email,
                name=candidate.name,
                bio=candidate.bio,
                age=candidate.age,
                gender=candidate.gender,
                city=candidate.city,
                interests=candidate.interests,
                tribe=candidate.tribe,
                religion=candidate.religion,
                relationship_status=candidate.relationship_status,
                has_kids=candidate.has_kids,
                height=candidate.height,
                occupation=candidate.occupation,
                photo_url=candidate.photo_url,
                score=compatibility_score(current_user, candidate),
            )
        )

    ranked.sort(key=lambda item: item.score, reverse=True)
    return ranked[:limit]


@router.get("/{user_id}", response_model=UserOut)
def get_profile(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user
