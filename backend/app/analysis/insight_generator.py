from datetime import datetime, timezone, timedelta
from app.analysis.frequency_comparison import (
    trigger_frequencies,
    symptom_category_frequencies,
    medication_effectiveness,
)

MIN_EPISODES_FOR_INSIGHTS = 5

def generate_insights(episodes: list) -> dict:
    total = len(episodes)
    if total < MIN_EPISODES_FOR_INSIGHTS:
        return {
            "has_enough_data": False,
            "total_episodes": total,
            "episodes_needed": MIN_EPISODES_FOR_INSIGHTS - total,
            "average_severity": None,
            "top_triggers": [],
            "top_symptom_categories": [],
            "medication_effectiveness": [],
            "recent_trend": None,
        }

    severities = [ep.overall_severity for ep in episodes]
    average_severity = round(sum(severities) / len(severities), 1)
    return {
        "has_enough_data": True,
        "total_episodes": total,
        "episodes_needed": 0,
        "average_severity": average_severity,
        "top_triggers": trigger_frequencies(episodes)[:5],
        "top_symptom_categories": symptom_category_frequencies(episodes)[:5],
        "medication_effectiveness": medication_effectiveness(episodes),
        "recent_trend": _recent_trend(episodes),
    }

def _recent_trend(episodes: list) -> dict:
    now = datetime.now(timezone.utc)

    def _aware(dt):
        return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)
    last_14 = sum(1 for ep in episodes if _aware(ep.date) >= now - timedelta(days=14))
    prior_14 = sum(
        1 for ep in episodes
        if now - timedelta(days=28) <= _aware(ep.date) < now - timedelta(days=28) 
    )

    if prior_14 == 0:
        direction = "up" if last_14 > 0 else "flat"
    elif last_14 > prior_14:
        direction = "up"
    elif last_14 < prior_14:
        direction = "down"
    else:
        direction = "flat"

    return {
        "direction": direction,
        "episodes_last_14_days": last_14,
        "episodes_prior_14_days": prior_14,
    }