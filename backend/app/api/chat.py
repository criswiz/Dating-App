from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.user import User
from app.models.social import Match, ChatThread, Message
from app.schemas.social import ThreadOut, MessageOut, SendMessageRequest
from app.services.deps import get_current_user

router = APIRouter()


def _thread_for_user_or_404(db: Session, thread_id: int, user_id: int) -> ChatThread:
    thread = db.query(ChatThread).filter(ChatThread.id == thread_id).first()
    if not thread:
        raise HTTPException(status_code=404, detail="Thread not found")
    match = db.query(Match).filter(Match.id == thread.match_id, Match.is_active.is_(True)).first()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")
    if user_id not in (match.user_a_id, match.user_b_id):
        raise HTTPException(status_code=403, detail="Not allowed in this thread")
    return thread


@router.get("/threads", response_model=list[ThreadOut])
def list_my_threads(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    threads = (
        db.query(ChatThread)
        .join(Match, Match.id == ChatThread.match_id)
        .filter(
            Match.is_active.is_(True),
            or_(Match.user_a_id == current_user.id, Match.user_b_id == current_user.id),
        )
        .all()
    )
    return threads


@router.get("/threads/{thread_id}/messages", response_model=list[MessageOut])
def get_thread_messages(
    thread_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _thread_for_user_or_404(db, thread_id, current_user.id)
    messages = (
        db.query(Message)
        .filter(Message.thread_id == thread_id)
        .order_by(Message.created_at.asc(), Message.id.asc())
        .all()
    )
    return messages


@router.post("/threads/{thread_id}/messages", response_model=MessageOut)
def send_message(
    thread_id: int,
    payload: SendMessageRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not payload.content.strip():
        raise HTTPException(status_code=400, detail="Message content cannot be empty")
    _thread_for_user_or_404(db, thread_id, current_user.id)
    msg = Message(thread_id=thread_id, sender_user_id=current_user.id, content=payload.content.strip())
    db.add(msg)
    db.commit()
    db.refresh(msg)
    return msg
