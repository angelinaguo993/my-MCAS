"""
Database model for a logged MCAS episode (triggers + symptoms stored as json columns)
"""

from sqlalchemy import Column, Integer, String, DateTime, JSON, Boolean, Float
from datetime import datetime, timezone
from app.db.database import Base


class Episode(Base):
    __tablename__ = "episodes"

    id = Column(Integer, primary_key=True, index=True)
    date = Column(DateTime, default=lambda: datetime.now(timezone.utc), index=True)
    end_date = Column(DateTime, nullable=True)
    weather_summary = Column(String, nullable=True)

    # Triggers: list of strings, e.g. ["high_histamine_food", "stress", "heat"]
    triggers = Column(JSON, default=list)

    # Symptoms: list of {"category": str, "severity": int} dicts
    symptoms = Column(JSON, default=list)

    overall_severity = Column(Integer, nullable=False)  # 1-10

    medication_taken = Column(Boolean, default=False)
    medication_names = Column(JSON, default=list)
    medication_helped = Column(Boolean, nullable=True)

    notes = Column(String, nullable=True)

    sleep_hours = Column(Float, nullable=True)  # hours of sleep the night before
    
