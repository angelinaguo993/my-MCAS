import Foundation

struct Episode: Identifiable, Codable, Equatable {
    var id: String
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
        case weatherSummary = "weather_summary"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle ID as either an Int or String from the backend
        if let intId = try? container.decode(Int.self, forKey: .id) {
            id = String(intId)
        } else if let stringId = try? container.decode(String.self, forKey: .id) {
            id = stringId
        } else {
            id = UUID().uuidString
        }
        
        date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        triggers = try container.decodeIfPresent([Trigger].self, forKey: .triggers) ?? []
        symptoms = try container.decodeIfPresent([SymptomEntry].self, forKey: .symptoms) ?? []
        overallSeverity = try container.decodeIfPresent(Int.self, forKey: .overallSeverity) ?? 5
        medicationTaken = try container.decodeIfPresent(Bool.self, forKey: .medicationTaken) ?? false
        medicationNames = try container.decodeIfPresent([String].self, forKey: .medicationNames) ?? []
        medicationHelped = try container.decodeIfPresent(Bool.self, forKey: .medicationHelped)
        foodEaten = try container.decodeIfPresent(String.self, forKey: .foodEaten)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        weatherSummary = try container.decodeIfPresent(String.self, forKey: .weatherSummary)
    }

    init(id: String = UUID().uuidString, date: Date = Date(), triggers: [Trigger] = [], symptoms: [SymptomEntry] = [], overallSeverity: Int = 5, medicationTaken: Bool = false, medicationNames: [String] = [], medicationHelped: Bool? = nil, foodEaten: String? = nil, notes: String? = nil, weatherSummary: String? = nil) {
        self.id = id
        self.date = date
        self.triggers = triggers
        self.symptoms = symptoms
        self.overallSeverity = overallSeverity
        self.medicationTaken = medicationTaken
        self.medicationNames = medicationNames
        self.medicationHelped = medicationHelped
        self.foodEaten = foodEaten
        self.notes = notes
        self.weatherSummary = weatherSummary
    }
}