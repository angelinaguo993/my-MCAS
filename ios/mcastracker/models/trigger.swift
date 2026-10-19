import Foundation

enum Trigger: String, CaseIterable, Codable, Identifiable {
    /// categories of triggers
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
    case barometricPressure = "barometric_pressure"
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
        case .barometricPressure: return "Barometric pressure changes"

        case .other: return "Other"
        }
    }

    /// graphic shown alongside each category of triggers in the UI
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
        case .barometricPressure: return "gauge.with.dots.needle.67percent"
        
        case .other: return "questionmark.circle.fill"
        }
    }

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
            case .barometricPressure: return nil
            case .other: return "Describe the trigger"
        }
    }

    static func from(rawValue: String) -> Trigger? {
        let cleaned = rawValue.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
        
        if let match = Trigger(rawValue: cleaned) {
            return match
        }
        
        return Trigger.allCases.first {
            $0.rawValue.lowercased() == cleaned ||
            $0.displayName.lowercased() == rawValue.lowercased()
        }
    }
}
