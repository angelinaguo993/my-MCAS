"""
Routes covering all three core flows:
  - GET  /dashboard              -> "days since last episode" card
  - POST /episodes               -> submit the survey
  - GET  /episodes                -> list for the calendar view
  - GET  /episodes/{episode_id}   -> single episode detail (tap a calendar day)
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import extract
from datetime import datetime, timezone
from typing import Optional

from app.db.database import get_db
from app.models.episode import Episode
from app.schemas.episode_schema import EpisodeCreate, EpisodeResponse, DashboardResponse

router = APIRouter()


@router.get("/dashboard", response_model=DashboardResponse)
def get_dashboard(db: Session = Depends(get_db)):
    latest = db.query(Episode).order_by(Episode.date.desc()).first()
    total = db.query(Episode).count()

    if latest is None:
        return DashboardResponse(
            days_since_last_episode=None,
            last_episode_date=None,
            total_episodes_logged=0,
        )

    last_date = latest.date
    if last_date.tzinfo is None:
        last_date = last_date.replace(tzinfo=timezone.utc)
    days_since = (datetime.now(timezone.utc) - last_date).days

    return DashboardResponse(
        days_since_last_episode=days_since,
        last_episode_date=latest.date,
        total_episodes_logged=total,
    )


@router.post("/episodes", response_model=EpisodeResponse, status_code=201)
def create_episode(payload: EpisodeCreate, db: Session = Depends(get_db)):
    episode = Episode(
        triggers=payload.triggers,
        symptoms=[s.model_dump() for s in payload.symptoms],
        overall_severity=payload.overall_severity,
        medication_taken=payload.medication_taken,
        medication_names=payload.medication_names,
        medication_helped=payload.medication_helped,
        notes=payload.notes,
    )
    db.add(episode)
    db.commit()
    db.refresh(episode)
    return episode


@router.get("/episodes", response_model=list[EpisodeResponse])
def list_episodes(
    year: Optional[int] = None,
    month: Optional[int] = None,
    db: Session = Depends(get_db),
):
    """Used by the calendar view. Pass ?year=2026&month=9 to filter one month."""
    query = db.query(Episode)
    if year is not None:
        query = query.filter(extract("year", Episode.date) == year)
    if month is not None:
        query = query.filter(extract("month", Episode.date) == month)
    return query.order_by(Episode.date.desc()).all()


@router.get("/episodes/{episode_id}", response_model=EpisodeResponse)
def get_episode(episode_id: int, db: Session = Depends(get_db)):
    episode = db.query(Episode).filter(Episode.id == episode_id).first()
    if episode is None:
        raise HTTPException(status_code=404, detail="Episode not found")
    return episode
