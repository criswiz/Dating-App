from __future__ import annotations

from app.models.user import User


def profile_completeness_score(candidate: User) -> float:
    fields = [candidate.name, candidate.bio, candidate.age, candidate.city, candidate.interests]
    completed = sum(1 for value in fields if value not in (None, ""))
    return (completed / len(fields)) * 30.0


def shared_interests_score(current_user: User, candidate: User) -> float:
    if not current_user.interests or not candidate.interests:
        return 0.0
    current = {item.strip().lower() for item in current_user.interests.split(",") if item.strip()}
    other = {item.strip().lower() for item in candidate.interests.split(",") if item.strip()}
    if not current or not other:
        return 0.0
    overlap = len(current.intersection(other))
    return min(25.0, overlap * 8.0)


def intent_score(current_user: User, candidate: User) -> float:
    if current_user.intent and candidate.intent and current_user.intent == candidate.intent:
        return 20.0
    return 5.0


def activity_score(candidate: User) -> float:
    # Lightweight default in a no-cost engine; can be replaced by recency decay.
    return 10.0 if candidate.last_active_at else 0.0


def compatibility_score(current_user: User, candidate: User) -> float:
    score = (
        profile_completeness_score(candidate)
        + shared_interests_score(current_user, candidate)
        + intent_score(current_user, candidate)
        + activity_score(candidate)
    )
    return round(min(100.0, score), 2)
