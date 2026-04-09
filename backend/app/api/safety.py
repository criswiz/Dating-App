from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.user import User
from app.models.social import UserBlock, UserReport
from app.schemas.social import BlockRequest, ReportRequest
from app.services.deps import get_current_user, get_current_admin

router = APIRouter()


@router.post("/block")
def block_user(
    payload: BlockRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if payload.blocked_user_id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot block yourself")
    target = db.query(User).filter(User.id == payload.blocked_user_id).first()
    if not target:
        raise HTTPException(status_code=404, detail="User not found")
    existing = (
        db.query(UserBlock)
        .filter(
            UserBlock.blocker_user_id == current_user.id,
            UserBlock.blocked_user_id == payload.blocked_user_id,
        )
        .first()
    )
    if existing:
        return {"status": "already_blocked"}
    db.add(
        UserBlock(
            blocker_user_id=current_user.id,
            blocked_user_id=payload.blocked_user_id,
            reason=payload.reason,
        )
    )
    db.commit()
    return {"status": "blocked"}


@router.post("/report")
def report_user(
    payload: ReportRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if payload.reported_user_id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot report yourself")
    target = db.query(User).filter(User.id == payload.reported_user_id).first()
    if not target:
        raise HTTPException(status_code=404, detail="User not found")
    db.add(
        UserReport(
            reporter_user_id=current_user.id,
            reported_user_id=payload.reported_user_id,
            reason=payload.reason.strip(),
            status="open",
        )
    )
    db.commit()
    return {"status": "reported"}


@router.get("/moderation/queue")
def moderation_queue(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin),
):
    reports = db.query(UserReport).order_by(UserReport.created_at.desc()).all()
    return [
        {
            "id": report.id,
            "reporter_user_id": report.reporter_user_id,
            "reported_user_id": report.reported_user_id,
            "reason": report.reason,
            "status": report.status,
            "created_at": report.created_at,
        }
        for report in reports
    ]


@router.post("/verify/{user_id}")
def verify_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.is_verified = True
    db.commit()
    return {"status": "verified", "user_id": user_id}


@router.post("/ban/{user_id}")
def ban_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if user.role == "admin":
        raise HTTPException(status_code=400, detail="Cannot ban an admin user")
    user.is_banned = True
    db.commit()
    return {"status": "banned", "user_id": user_id}


@router.post("/unban/{user_id}")
def unban_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.is_banned = False
    db.commit()
    return {"status": "unbanned", "user_id": user_id}
