from pydantic import BaseModel, EmailStr, field_validator, ConfigDict
from typing import Optional
from datetime import datetime

_STR_FIELDS = [
    'bio', 'name', 'gender', 'intent', 'city', 'interests', 'tribe',
    'religion', 'relationship_status', 'has_kids', 'want_kids',
    'education', 'occupation', 'drinking', 'smoking', 'exercise', 'languages',
]


class UserCreate(BaseModel):
    email: EmailStr
    password: str
    name: Optional[str] = None
    bio: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    intent: Optional[str] = None
    city: Optional[str] = None
    interests: Optional[str] = None
    tribe: Optional[str] = None
    religion: Optional[str] = None
    relationship_status: Optional[str] = None
    has_kids: Optional[str] = None
    want_kids: Optional[str] = None
    height: Optional[int] = None
    education: Optional[str] = None
    occupation: Optional[str] = None
    drinking: Optional[str] = None
    smoking: Optional[str] = None
    exercise: Optional[str] = None
    languages: Optional[str] = None

    @field_validator('age')
    @classmethod
    def validate_age(cls, v):
        if v is not None and (v < 18 or v > 120):
            raise ValueError('Age must be between 18 and 120')
        return v

    @field_validator('height')
    @classmethod
    def validate_height(cls, v):
        if v is not None and (v < 50 or v > 300):
            raise ValueError('Height must be between 50 and 300 cm')
        return v

    @field_validator(*_STR_FIELDS, mode='before')
    @classmethod
    def validate_string_length(cls, v):
        if v is not None and len(str(v).strip()) > 500:
            raise ValueError('Field must be 500 characters or less')
        return v.strip() if isinstance(v, str) else v


class ProfileUpdate(BaseModel):
    name: Optional[str] = None
    bio: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    intent: Optional[str] = None
    city: Optional[str] = None
    interests: Optional[str] = None
    tribe: Optional[str] = None
    religion: Optional[str] = None
    relationship_status: Optional[str] = None
    has_kids: Optional[str] = None
    want_kids: Optional[str] = None
    height: Optional[int] = None
    education: Optional[str] = None
    occupation: Optional[str] = None
    drinking: Optional[str] = None
    smoking: Optional[str] = None
    exercise: Optional[str] = None
    languages: Optional[str] = None

    @field_validator('age')
    @classmethod
    def validate_age(cls, v):
        if v is not None and (v < 18 or v > 120):
            raise ValueError('Age must be between 18 and 120')
        return v

    @field_validator('height')
    @classmethod
    def validate_height(cls, v):
        if v is not None and (v < 50 or v > 300):
            raise ValueError('Height must be between 50 and 300 cm')
        return v

    @field_validator(*_STR_FIELDS, mode='before')
    @classmethod
    def validate_string_length(cls, v):
        if v is not None and len(str(v).strip()) > 500:
            raise ValueError('Field must be 500 characters or less')
        return v.strip() if isinstance(v, str) else v


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class PasswordResetRequest(BaseModel):
    email: EmailStr


class PasswordResetConfirm(BaseModel):
    token: str
    new_password: str


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    email: EmailStr
    name: Optional[str] = None
    bio: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    intent: Optional[str] = None
    city: Optional[str] = None
    interests: Optional[str] = None
    tribe: Optional[str] = None
    religion: Optional[str] = None
    relationship_status: Optional[str] = None
    has_kids: Optional[str] = None
    want_kids: Optional[str] = None
    height: Optional[int] = None
    education: Optional[str] = None
    occupation: Optional[str] = None
    drinking: Optional[str] = None
    smoking: Optional[str] = None
    exercise: Optional[str] = None
    languages: Optional[str] = None
    photo_url: Optional[str] = None
    is_verified: bool
    created_at: datetime


class Token(BaseModel):
    access_token: str
    refresh_token: Optional[str] = None
    token_type: str = "bearer"
