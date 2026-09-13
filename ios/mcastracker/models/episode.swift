import Foundation

/// A single logged MCAS episode. Mirrors the backend's EpisodeCreate/
/// EpisodeResponse schema (see backend/app/schemas/episode_schema.py) —
/// keep the two in sync any time a field is added.
struct Episode: Identifiable, Codable, Equatable {
    var id: Int?              // nil until the backend assigns one on save
    var date: Date = Date()
    var triggers: [Trigger] = []
    var symptoms: [SymptomEntry] = []
    var overallSeverity: Int = 5   // 1-10
    var medicationTaken: Bool = false
    var medicationName: String? = nil
    var medicationHelped: Bool? = nil
    var foodEaten: String? = nil
    var notes: String? = nil

    // var specificMedication: [String] {
    //     switch self {
    //     case .general:
    //         return ["H1 Antihistamines", "H2 Antihistamines", "Mast Cell Stabilizers", "Leukotriene Inhbitors"]
    //     }
    // }

    enum CodingKeys: String, CodingKey {
        case id, date, triggers, symptoms
        case overallSeverity = "overall_severity"
        case medicationTaken = "medication_taken"
        case medicationName = "medication_name"
        case medicationHelped = "medication_helped"
        case foodEaten = "food_eaten"
        case notes
    }
}
