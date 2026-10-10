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
    case drugs = "drugs"
    case venoms = "venoms"
    case allergies = "allergies"
    case other = "other"


    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .highHistamineFood: return "High-histamine food"
        case .heat: return "Heat exposure"
        case .cold: return "Cold exposure"
        case .stress: return "Stress"
        case .exercise: return "Exercise / exertion"
        case .fragrance: return "Fragrance / chemical exposure"
        case .alcohol: return "Alcohol / beverages"
        case .lackOfSleep: return "Lack of sleep"
        case .friction: return "Skin friction / pressure"
        case .drugs: return "Drugs (opioids, NSAIDS, antibiotics, etc.)"
        case .venoms: return "Venoms (insect stings, snake bites, spider bites, etc.)"
        case .allergies: return "Allergies (pollen, dust, pet dander, etc.)"

        case .other: return "Other"
        }
    }

    /// SF Symbol shown alongside this trigger on the dashboard's insights cards.
    var iconName: String {
        switch self {
        case .highHistamineFood: return "fork.knife"
        case .heat: return "sun.max.fill"
        case .cold: return "snowflake"
        case .stress: return "bolt.fill"
        case .exercise: return "figure.run"
        case .fragrance: return "wind"
        case .alcohol: return "wineglass.fill"
        case .lackOfSleep: return "bed.double.fill"
        case .friction: return "hand.raised.fill"
        case .drugs: return "pills"
        case .venoms: return "skull"
        case .allergies: return "leaf.fill"
        
        case .other: return "questionmark.circle.fill"
        }
    }

    /// Placeholder for the detail box shown when this trigger is selected
    var detailPlaceholder: String? {
        switch self {
            case .highHistamineFood: return "What did you eat prior to this episode?"
            case .alcohol: return "What did you drink prior to this episode?"
            case .fragrance: return "What scent or product may have caused this episode?"
            case .exercise: return "What activity did you do prior/while experiencing this episode?"
            case .heat: return nil
            case .cold: return nil
            case .stress: return "What was stressful?"
            case .friction: return "Where on your skin?"
            case .lackOfSleep: return nil
            case .drugs: return "What drug(s) or other medication did you take prior to this episode?"
            case .venoms: return "What bit or stung you prior/while experiencing this episode?"
            case .allergies: return "What allergen(s) may have caused this episode?"
            case .other: return "Describe the trigger"
        }
    }

    /// Looks up a trigger by raw backend string
    static func from(rawValue: String) -> Trigger? {
        let cleaned = rawValue.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
        
        // 1. Check exact rawValue match
        if let match = Trigger(rawValue: cleaned) {
            return match
        }
        
        // 2. Check case-insensitive match against rawValues or display names
        return Trigger.allCases.first {
            $0.rawValue.lowercased() == cleaned ||
            $0.displayName.lowercased() == rawValue.lowercased()
        }
    }
}