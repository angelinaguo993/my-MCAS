"""
pulls out top triggers, symptom, patterns, medication effectiveness, basic stats, 
from database history
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.episode import Episode
from app.schemas.episode_schema import InsightsResponse
from app.analysis.insight_generator import generate_insights

router = APIRouter()


@router.get("/insights", response_model=InsightsResponse)
def get_insights(db: Session = Depends(get_db)):
    episodes = db.query(Episode).all()
    return generate_insights(episodes)