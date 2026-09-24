from collections import Counter
from app.analysis.confidence_intervals import wilson_score_interval

def trigger_frequencies(episodes: list) -> list[dict]:
    total = len(episodes)
    if total == 0:
        return []

    counts = Counter()
    for ep in episodes:
        for trigger in ep.triggers or []:
            if isinstance(trigger, str):
                counts[trigger] += 1

    results = []
    for trigger, count in counts.items():
        interval = wilson_score_interval(count, total)
        results.append({"name": trigger, "count": count, **interval})

    results.sort(key=lambda x: x["count"], reverse=True)
    return results

def symptom_category_frequencies(episodes: list) -> list[dict]:
    total = len(episodes)
    if total == 0:
        return []

    counts = Counter()
    for ep in episodes:
        for symptom in ep.symptoms or []:
            category = symptom.get("category")
            if category:
                counts[category] += 1

    results = []
    for category, count in counts.items():
        interval = wilson_score_interval(count, total)
        results.append({"name": category, "count": count, **interval})

    results.sort(key=lambda x: x["count"], reverse=True)
    return results

def medication_effectiveness(episodes: list) -> list[dict]:
    taken_counts = Counter()
    helped_counts = Counter()

    for ep in episodes:
        if not ep.medication_taken:
            continue
        helped = bool(ep.medication_helped)
        for med in ep.medications or []:
            taken_counts[med] += 1
            if helped:
                helped_counts[med] += 1


    results = []
    for med, taken in taken_counts.items():
        interval = wilson_score_interval(helped_counts[med],taken)
        results.append({"name": med, "count": taken, **interval})

    results.sort(key=lambda x: x["count"], reverse=True)
    return results

