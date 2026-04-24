from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import or_, and_
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.user import User
from app.models.social import Interaction, Match, ChatThread, UserBlock
from app.schemas.social import InteractionRequest, InteractionResult, MatchOut, MatchWithProfile
from app.services.deps import get_current_user
from app.services.rate_limit import interaction_limiter

router = APIRouter()


def _pair(user_id_1: int, user_id_2: int) -> tuple[int, int]:
    return (user_id_1, user_id_2) if user_id_1 < user_id_2 else (user_id_2, user_id_1)


def _has_block(db: Session, actor_user_id: int, other_user_id: int) -> bool:
    return (
        db.query(UserBlock)
        .filter(
            or_(
                and_(
                    UserBlock.blocker_user_id == actor_user_id,
                    UserBlock.blocked_user_id == other_user_id,
                ),
                and_(
                    UserBlock.blocker_user_id == other_user_id,
                    UserBlock.blocked_user_id == actor_user_id,
                ),
            )
        )
        .first()
        is not None
    )


@router.post("/like", response_model=InteractionResult)
def like_user(
    payload: InteractionRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if payload.target_user_id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot like yourself")
    target = db.query(User).filter(User.id == payload.target_user_id).first()
    if not target:
        raise HTTPException(status_code=404, detail="Target user not found")
    if _has_block(db, current_user.id, target.id):
        raise HTTPException(status_code=403, detail="Interaction forbidden by block relationship")
    if not interaction_limiter.allow(f"user:{current_user.id}"):
        raise HTTPException(status_code=429, detail="Rate limit exceeded")

    interaction = (
        db.query(Interaction)
        .filter(
            Interaction.actor_user_id == current_user.id,
            Interaction.target_user_id == payload.target_user_id,
        )
        .first()
    )
    if interaction:
        interaction.action = "like"
    else:
        interaction = Interaction(
            actor_user_id=current_user.id,
            target_user_id=payload.target_user_id,
            action="like",
        )
        db.add(interaction)
    db.commit()

    reciprocal_like = (
        db.query(Interaction)
        .filter(
            Interaction.actor_user_id == payload.target_user_id,
            Interaction.target_user_id == current_user.id,
            Interaction.action == "like",
        )
        .first()
    )

    if reciprocal_like:
        user_a_id, user_b_id = _pair(current_user.id, payload.target_user_id)
        existing_match = (
            db.query(Match)
            .filter(Match.user_a_id == user_a_id, Match.user_b_id == user_b_id)
            .first()
        )
        if not existing_match:
            existing_match = Match(user_a_id=user_a_id, user_b_id=user_b_id, is_active=True)
            db.add(existing_match)
            db.flush()  # Assign id to existing_match
            db.add(ChatThread(match_id=existing_match.id))
            db.commit()
            db.refresh(existing_match)
        return InteractionResult(matched=True, match_id=existing_match.id)

    return InteractionResult(matched=False, match_id=None)


@router.post("/pass", response_model=InteractionResult)
def pass_user(
    payload: InteractionRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if payload.target_user_id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot pass yourself")
    target = db.query(User).filter(User.id == payload.target_user_id).first()
    if not target:
        raise HTTPException(status_code=404, detail="Target user not found")
    if not interaction_limiter.allow(f"user:{current_user.id}"):
        raise HTTPException(status_code=429, detail="Rate limit exceeded")

    interaction = (
        db.query(Interaction)
        .filter(
            Interaction.actor_user_id == current_user.id,
            Interaction.target_user_id == payload.target_user_id,
        )
        .first()
    )
    if interaction:
        interaction.action = "pass"
    else:
        interaction = Interaction(
            actor_user_id=current_user.id,
            target_user_id=payload.target_user_id,
            action="pass",
        )
        db.add(interaction)
    db.commit()
    return InteractionResult(matched=False, match_id=None)


@router.get("/", response_model=list[MatchWithProfile])
def list_matches(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    matches = (
        db.query(Match)
        .filter(
            Match.is_active.is_(True),
            or_(Match.user_a_id == current_user.id, Match.user_b_id == current_user.id),
        )
        .order_by(Match.created_at.desc())
        .all()
    )
    result = []
    for m in matches:
        other_id = m.user_b_id if m.user_a_id == current_user.id else m.user_a_id
        other = db.query(User).filter(User.id == other_id).first()
        result.append(MatchWithProfile(
            id=m.id,
            user_a_id=m.user_a_id,
            user_b_id=m.user_b_id,
            is_active=m.is_active,
            created_at=m.created_at,
            other_user_id=other_id,
            other_name=other.name if other else None,
            other_photo_url=other.photo_url if other else None,
            other_age=other.age if other else None,
            other_city=other.city if other else None,
        ))
    return result
