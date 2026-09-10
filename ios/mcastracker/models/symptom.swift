import Foundation

/// The organ-system categories an MCAS episode's symptoms can fall into.
/// Kept as an enum (not free-text) so the analysis engine can reliably
/// group/compare symptoms across episodes.
enum SymptomCategory: String, CaseIterable, Codable, Identifiable {
    case skin
    case gi
    case respiratory
    case cardiovascular
    case neurological
    case general

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .skin: return "Skin (hives, flushing, itching)"
        case .gi: return "GI (nausea, cramping, diarrhea)"
        case .respiratory: return "Respiratory (wheezing, throat tightness)"
        case .cardiovascular: return "Cardiovascular (rapid heart rate, dizziness)"
        case .neurological: return "Neurological (brain fog, headache)"
        case .general: return "General (fatigue)"
        }
    }
}

/// One symptom entry within an episode — a category plus its own severity,
/// since a single episode can hit multiple systems at different intensities.
struct SymptomEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    var category: SymptomCategory
    var severity: Int // 1-10

    enum CodingKeys: String, CodingKey {
        case category, severity
    }
}
