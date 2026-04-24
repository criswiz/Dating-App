from datetime import datetime
from pydantic import BaseModel, ConfigDict


class DiscoveryCandidate(BaseModel):
    id: int
    email: str
    name: str | None
    bio: str | None
    age: int | None
    gender: str | None
    city: str | None
    interests: str | None
    tribe: str | None
    religion: str | None
    relationship_status: str | None
    has_kids: str | None
    height: int | None
    occupation: str | None
    photo_url: str | None
    score: float


class InteractionRequest(BaseModel):
    target_user_id: int


class InteractionResult(BaseModel):
    matched: bool
    match_id: int | None = None


class MatchOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_a_id: int
    user_b_id: int
    is_active: bool
    created_at: datetime


class MatchWithProfile(BaseModel):
    id: int
    user_a_id: int
    user_b_id: int
    is_active: bool
    created_at: datetime
    other_user_id: int
    other_name: str | None
    other_photo_url: str | None
    other_age: int | None
    other_city: str | None


class SendMessageRequest(BaseModel):
    content: str


class MessageOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    thread_id: int
    sender_user_id: int
    content: str
    created_at: datetime


class ThreadOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    match_id: int
    created_at: datetime


class ReportRequest(BaseModel):
    reported_user_id: int
    reason: str


class BlockRequest(BaseModel):
    blocked_user_id: int
    reason: str | None = None
