"""
Pydantic schemas — these define what the API accepts and returns.
Kept separate from the SQLAlchemy models (app/models) so the DB shape
and the API contract can evolve independently.
"""
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional


class SymptomEntry(BaseModel):
    category: str  # "skin" | "gi" | "respiratory" | "cardiovascular" | "neurological" | "general"
    severity: int = Field(ge=1, le=10)
    specific_symptoms: list[str] = []  # e.g. ["Hives", "Itching"] for category "skin"


class EpisodeCreate(BaseModel):
    """What the Swift app sends when submitting the survey."""
    triggers: list[str] = []
    symptoms: list[SymptomEntry] = []
    overall_severity: int = Field(ge=1, le=10)
    medication_taken: bool = False
    medication_names: list[str] = []
    medication_helped: Optional[bool] = None
    notes: Optional[str] = None


class EpisodeResponse(EpisodeCreate):
    """What the API sends back — same fields plus server-assigned id/date."""
    id: int
    date: datetime

    class Config:
        from_attributes = True  # lets this build directly from a SQLAlchemy Episode


class DashboardResponse(BaseModel):
    days_since_last_episode: Optional[int]  # None if no episodes logged yet
    last_episode_date: Optional[datetime]
    total_episodes_logged: int
