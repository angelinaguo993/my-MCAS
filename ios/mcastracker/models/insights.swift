import Foundation

/// Mirrors the backend's FrequencyStat (see episode_schema.py) — one
/// trigger/symptom/medication's frequency, with a confidence interval.
struct FrequencyStat: Codable, Identifiable {
    var id: String { name }
    let name: String
    let proportion: Double
    let lower: Double
    let upper: Double
    let sampleSize: Int

    enum CodingKeys: String, CodingKey {
        case name, proportion, lower, upper
        case sampleSize = "sample_size"
    }
}

struct TrendInfo: Codable {
    let episodesLast14Days: Int
    let episodesPrior14Days: Int
    let direction: String  // "up" | "down" | "flat"

    enum CodingKeys: String, CodingKey {
        case episodesLast14Days = "episodes_last_14_days"
        case episodesPrior14Days = "episodes_prior_14_days"
        case direction
    }
}

/// Mirrors the backend's InsightsResponse — the full output of GET /insights.
struct InsightsResponse: Codable {
    let hasEnoughData: Bool
    let totalEpisodes: Int
    let episodesNeeded: Int
    let averageSeverity: Double?
    let topTriggers: [FrequencyStat]
    let topSymptomCategories: [FrequencyStat]
    let medicationEffectiveness: [FrequencyStat]
    let recentTrend: TrendInfo?

    enum CodingKeys: String, CodingKey {
        case hasEnoughData = "has_enough_data"
        case totalEpisodes = "total_episodes"
        case episodesNeeded = "episodes_needed"
        case averageSeverity = "average_severity"
        case topTriggers = "top_triggers"
        case topSymptomCategories = "top_symptom_categories"
        case medicationEffectiveness = "medication_effectiveness"
        case recentTrend = "recent_trend"
    }
}