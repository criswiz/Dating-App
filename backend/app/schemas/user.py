from pydantic import BaseModel, EmailStr, field_validator, ConfigDict
from typing import Optional
from datetime import datetime


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

    @field_validator('age')
    @classmethod
    def validate_age(cls, v):
        if v is not None and (v < 18 or v > 120):
            raise ValueError('Age must be between 18 and 120')
        return v

    @field_validator('bio', 'name', 'gender', 'intent', 'city', 'interests', mode='before')
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

    @field_validator('age')
    @classmethod
    def validate_age(cls, v):
        if v is not None and (v < 18 or v > 120):
            raise ValueError('Age must be between 18 and 120')
        return v

    @field_validator('bio', 'name', 'gender', 'intent', 'city', 'interests', mode='before')
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
    photo_url: Optional[str] = None
    is_verified: bool
    created_at: datetime


class Token(BaseModel):
    access_token: str
    refresh_token: Optional[str] = None
    token_type: str = "bearer"
