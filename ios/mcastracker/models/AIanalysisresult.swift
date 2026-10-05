import Foundation

struct AIAnalysisResult: Codable {
    let triggersToAvoid: [String]
    let medicationInsights: [String]
    let notesAnalysis: [String]
}