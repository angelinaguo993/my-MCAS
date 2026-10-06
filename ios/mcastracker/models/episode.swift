import Foundation

struct Episode: Identifiable, Codable, Equatable {
    var id: UUID
    var date: Date = Date()
    var triggers: [Trigger] = []
    var symptoms: [SymptomEntry] = []
    var overallSeverity: Int = 5   // 1-10
    var medicationTaken: Bool = false
    var medicationNames: [String] = []
    var medicationHelped: Bool? = nil
    var foodEaten: String? = nil
    var notes: String? = nil
    var weatherSummary: String? = nil


    enum CodingKeys: String, CodingKey {
        case id, date, triggers, symptoms
        case overallSeverity = "overall_severity"
        case medicationTaken = "medication_taken"
        case medicationNames = "medication_names"
        case medicationHelped = "medication_helped"
        case foodEaten = "food_eaten"
        case notes
    }
}
