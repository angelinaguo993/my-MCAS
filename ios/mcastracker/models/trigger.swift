import Foundation

/// Common MCAS triggers a user can multi-select while logging an episode.
/// Kept as an enum for now (fixed list) — swap for a user-editable list later
/// if you want people to add their own custom triggers.
enum Trigger: String, CaseIterable, Codable, Identifiable {
    case highHistamineFood = "high_histamine_food"
    case heat = "heat"
    case cold = "cold"
    case stress = "stress"
    case exercise = "exercise"
    case fragrance = "fragrance"
    case alcohol = "alcohol"
    case lackOfSleep = "lack_of_sleep"
    case friction = "friction"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .highHistamineFood: return "High-histamine food"
        case .heat: return "Heat exposure"
        case .cold: return "Cold exposure"
        case .stress: return "Stress"
        case .exercise: return "Exercise / exertion"
        case .fragrance: return "Fragrance / chemical exposure"
        case .alcohol: return "Alcohol"
        case .lackOfSleep: return "Lack of sleep"
        case .friction: return "Skin friction / pressure"
        }
    }
}
