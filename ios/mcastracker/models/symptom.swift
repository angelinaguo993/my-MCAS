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
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .skin: return "Skin (hives, flushing, itching)"
        case .gi: return "GI (nausea, cramping, diarrhea)"
        case .respiratory: return "Respiratory (wheezing, throat tightness)"
        case .cardiovascular: return "Cardiovascular (rapid heart rate, dizziness)"
        case .neurological: return "Neurological (brain fog, headache)"
        case .general: return "General (fatigue)"
        case .other: return "Other"
        }
    }

    /// The specific, checkable symptoms shown once this category is selected.
    /// Keeping this as a fixed list (rather than free text) means the analysis
    /// engine can compare specific symptoms across episodes, not just categories.
    /// ".other" has no fixed list — the View shows a text field for it instead,
    /// and that typed description gets stored using this same specificSymptoms
    /// array on SymptomEntry (see below), just with free text instead of a
    /// pick from this list.
    var specificSymptoms: [String] {
        switch self {
        case .skin:
            return ["Hives", "Flushing", "Itching", "Swelling"]
        case .gi:
            return ["Nausea", "Vomiting", "Diarrhea", "Cramping", "Bloating"]
        case .respiratory:
            return ["Wheezing", "Throat tightness", "Nasal congestion", "Shortness of breath"]
        case .cardiovascular:
            return ["Rapid heart rate", "Lightheadedness", "Low blood pressure", "Fainting"]
        case .neurological:
            return ["Brain fog", "Headache", "Anxiety-like symptoms", "Tremor"]
        case .general:
            return ["Fatigue", "Chills", "Malaise"]
        case .other:
            return []
        }
    }
}

/// One symptom entry within an episode — a category, its own severity, and
/// which specific symptoms within that category occurred (e.g. category
/// "skin" with specificSymptoms ["Hives", "Itching"]). Specific symptoms are
/// optional — a user can log just the category + severity without checking
/// any boxes if they don't want to get that granular.
struct SymptomEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    var category: SymptomCategory
    var severity: Int // 1-10
    var specificSymptoms: [String] = []

    enum CodingKeys: String, CodingKey {
        case category, severity
        case specificSymptoms = "specific_symptoms"
    }
}