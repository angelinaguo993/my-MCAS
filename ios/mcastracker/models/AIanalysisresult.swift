import Foundation

struct AIAnalysisResult: Codable {
    let triggersToAvoid: [String]
    let medicationInsights: [String]
    let notesAnalysis: [String]
    let whatsNew: [String]
    let weatherInsights: [String]

    enum CodingKeys: String, CodingKey {
        case triggersToAvoid, medicationInsights, notesAnalysis
        case whatsNew = "whatsNew"
        case weatherInsights = "weatherInsights"
    }
}
