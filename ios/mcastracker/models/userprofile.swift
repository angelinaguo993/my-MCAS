import Foundation

enum BiologicalSex: String, CaseIterable, Codable, Identifiable {
    case male
    case female
    case intersex
    case preferNotToSay = "prefer_not_to_say"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .intersex: return "Intersex"
        case .preferNotToSay: return "Prefer not to say"
        }
    }
}

enum EpisodeFrequency: String, CaseIterable, Codable, Identifiable {
    case daily
    case fewTimesWeek = "few_times_week"
    case weekly
    case fewTimesMonth = "few_times_month"
    case monthlyOrLess = "monthly_or_less"
    case rarely

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .fewTimesWeek: return "A few times a week"
        case .weekly: return "Weekly"
        case .fewTimesMonth: return "A few times a month"
        case .monthlyOrLess: return "Monthly or less"
        case .rarely: return "Rarely"
        }
    }
}

/// The user's profile — collected once during onboarding, editable later
/// from Settings. This app has no login system, so there's exactly one
/// profile per install, stored locally on the device (not synced to the
/// backend — see UserProfileStore).
struct UserProfile: Codable, Equatable {
    var name: String = ""
    var age: Int? = nil
    var sex: BiologicalSex? = nil
    var location: String = ""
    var prescribedMedications: [String] = []
    var typicalEpisodeFrequency: EpisodeFrequency? = nil
    var previousSymptoms: [SymptomCategory] = []
    var previousTriggers: [Trigger] = []
}
