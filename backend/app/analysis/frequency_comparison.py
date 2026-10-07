from collections import Counter
from itertools import combinations
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
        for med in ep.medication_names or []:
            if isinstance(med, str):
                taken_counts[med] += 1
                if helped:
                    helped_counts[med] += 1

    results = []
    for med, taken in taken_counts.items():
        interval = wilson_score_interval(helped_counts[med], taken)
        results.append({"name": med, "count": taken, **interval})

    results.sort(key=lambda x: x["count"], reverse=True)
    return results

def trigger_cooccurrence(episodes: list) -> list[dict]:
    """
    analyzing pairs of triggers + how often they appear together in the same episode 
    -> 
    to help analyze how combinations of triggers cause episodes
    """
    
    total = len(episodes)
    if total == 0:
        return []

    pair_counts = Counter()
    for ep in episodes:
        triggers = sorted(set(t for t in (ep.triggers or []) if isinstance(t, str)))
        for pair in combinations(triggers, 2):
            pair_counts[pair] += 1

    results = []
    for pair, count in pair_counts.items():
        if count < 2:  # skip one-off coincidences — not a real pattern yet
            continue
        interval = wilson_score_interval(count, total)
        results.append({"name": " + ".join(pair), "count": count, **interval})

    results.sort(key=lambda x: x["count"], reverse=True)
    return results

def symptom_trigger_pairing(episodes: list) -> list[dict]:
    """
    For each (trigger, symptom category) pair, how often do they appear
    together in the same episode? Different from trigger_cooccurrence —
    this pairs a trigger against a symptom, not two triggers against
    each other (e.g. "high_histamine_food" tends to come with "gi"
    symptoms, "fragrance" tends to come with "respiratory").
    """
    total = len(episodes)
    if total == 0:
        return []

    pair_counts = Counter()
    for ep in episodes:
        triggers = set(t for t in (ep.triggers or []) if isinstance(t, str))
        categories = set(
            s.get("category") for s in (ep.symptoms or [])
            if isinstance(s, dict) and s.get("category")
        )
        for trigger in triggers:
            for category in categories:
                pair_counts[(trigger, category)] += 1

    results = []
    for (trigger, category), count in pair_counts.items():
        if count < 2:  # skip one-off coincidences
            continue
        interval = wilson_score_interval(count, total)
        results.append({"name": f"{trigger} → {category}", "count": count, **interval})

    results.sort(key=lambda x: x["count"], reverse=True)
    return results

def severity_by_trigger(episodes: list) -> list[dict]:
    """
    For each trigger, compares average severity on episodes where it was
    present vs. episodes where it wasn't — analyzes if a trigger makes the episode worse or not."
    """
    all_triggers = set()
    for ep in episodes:
        for t in (ep.triggers or []):
            if isinstance(t, str):
                all_triggers.add(t)

    results = []
    for trigger in all_triggers:
        with_trigger = [ep.overall_severity for ep in episodes if trigger in (ep.triggers or [])]
        without_trigger = [ep.overall_severity for ep in episodes if trigger not in (ep.triggers or [])]

        if len(with_trigger) < 2:  # not enough data for this specific trigger yet
            continue

        avg_with = sum(with_trigger) / len(with_trigger)
        avg_without = sum(without_trigger) / len(without_trigger) if without_trigger else avg_with

        results.append({
            "name": trigger,
            "avg_severity_with": round(avg_with, 1),
            "avg_severity_without": round(avg_without, 1),
            "sample_size": len(with_trigger),
        })

    results.sort(key=lambda x: x["avg_severity_with"] - x["avg_severity_without"], reverse=True)
    return results