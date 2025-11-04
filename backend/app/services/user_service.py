from sqlalchemy.orm import Session
from app.models.user import User
from app.services.auth import get_password_hash


def create_user(db: Session, email: str, password: str, name: str | None = None, bio: str | None = None):
    user = User(email=email, hashed_password=get_password_hash(password), name=name, bio=bio)
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def get_user_by_email(db: Session, email: str):
    return db.query(User).filter(User.email == email).first()


def get_user_by_id(db: Session, user_id: int):
    return db.query(User).filter(User.id == user_id).first()
