import math

#   Calculate the Wilson score interval for a given number of successes and total trials.

def wilson_score_interval(successes: int, total: int) -> dict:
    if total == 0:
        return {"proportion": 0.0, "lower": 1.0, "upper": 1.0, "sample_size": 0}

    z = 1.96
    p_hat = successes / total
    n = total

    denominator = 1 + (z ** 2) / n
    center = (p_hat + (z ** 2) / (2 * n)) / denominator
    margin = (z * math.sqrt((p_hat * (1 - p_hat) / n) + (z ** 2) / (4 * n ** 2))) / denominator

    return {
        "proportion": round(p_hat, 3),
        "lower": round(max(0.0, center - margin), 3),
        "upper": round(min(1.0, center + margin), 3),
        "sample_size": total,
    }
