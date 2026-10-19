import Foundation

enum SymptomCategory: String, CaseIterable, Codable, Identifiable {
    /// categories of symptoms
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

    /// checkable list of symptoms for each category when selected
    var specificSymptoms: [String] {
        switch self {
        case .skin:
            return ["Hives", "Flushing", "Itching", "Swelling"]
        case .gi:
            return ["Nausea", "Vomiting", "Diarrhea", "Cramping", "Bloating"]
        case .respiratory:
            return ["Wheezing", "Throat tightness", "Nasal congestion", "Shortness of breath"]
        case .cardiovascular:
            return ["Rapid heart rate", "Dizziness", "Lightheadedness", "Low blood pressure", "Fainting"]
        case .neurological:
            return ["Brain fog", "Headache", "Anxiety-like symptoms", "Tremor"]
        case .general:
            return ["Fatigue", "Chills", "Malaise"]
        case .other:
            return []
        }
    }
    
    /// graphic shown alongside each category of symptoms in the UI
    var iconName: String {
        switch self {
        case .skin: return "bandage.fill"
        case .gi: return "cross.case.fill"
        case .respiratory: return "wind"
        case .cardiovascular: return "heart.fill"
        case .neurological: return "brain.head.profile"
        case .general: return "figure.stand"
        case .other: return "questionmark.circle.fill"
        }
    }
}

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
