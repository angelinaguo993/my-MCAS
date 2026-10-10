import Foundation

enum DiscoverCategory: String, CaseIterable, Identifiable {
    case all, basics, triggers, diagnosis, care, safety

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .basics: return "Basics"
        case .triggers: return "Triggers"
        case .diagnosis: return "Diagnosis"
        case .care: return "Care"
        case .safety: return "Safety"
        }
    }
}

struct DiscoverFact: Identifiable {
    let id: String
    let category: DiscoverCategory
    let icon: String          // SF Symbol name
    let title: String
    let body: String
    let sourceName: String
    let sourceURL: URL?
}

struct DiscoverArticle: Identifiable {
    let id: String
    let source: String
    let title: String
    let summary: String
    let url: URL
}

/// Hand-written facts, paraphrased from the linked sources. This is static on purpose:
/// nothing here needs a server, and each item points to where it came from. To update
/// the content later, edit this file (or move it to a JSON file the backend serves).
enum DiscoverContent {
    static let lastReviewed = "October 2026"

    private static let cleveland = URL(string: "https://my.clevelandclinic.org/health/diseases/mast-cell-activation-syndrome")!
    private static let aanMCAS = URL(string: "https://allergyasthmanetwork.org/mast-cell-diseases/mcas/")!
    private static let aanDiseases = URL(string: "https://allergyasthmanetwork.org/mast-cell-diseases/")!
    private static let merck = URL(string: "https://www.merckmanuals.com/professional/immunology-allergic-disorders/allergic-autoimmune-and-other-hypersensitivity-disorders/mastocytosis-and-mast-cell-activation-syndrome")!
    private static let pmcReview = URL(string: "https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7731385/")!
    private static let pmcComorbidity = URL(string: "https://www.ncbi.nlm.nih.gov/pmc/articles/PMC13465963/")!

    static let facts: [DiscoverFact] = [
        DiscoverFact(
            id: "mast-cells",
            category: .basics,
            icon: "info.circle.fill",
            title: "What mast cells do",
            body: "Mast cells are immune cells that release chemicals like histamine when they sense a threat. In MCAS, they're thought to release those chemicals too easily, or at the wrong times.",
            sourceName: "Allergy & Asthma Network",
            sourceURL: aanMCAS
        ),
        DiscoverFact(
            id: "many-systems",
            category: .basics,
            icon: "person.fill",
            title: "Episodes can reach many body systems",
            body: "MCAS episodes typically involve two or more body systems at once, such as the skin (hives, flushing), digestion (nausea, cramping, diarrhea), heart and circulation (a racing heart, dizziness), or breathing.",
            sourceName: "Cleveland Clinic",
            sourceURL: cleveland
        ),
        DiscoverFact(
            id: "come-and-go",
            category: .basics,
            icon: "waveform.path.ecg",
            title: "Symptoms come and go",
            body: "Between episodes, symptoms often improve or disappear completely. That's part of why it can take so long to figure out what's happening, and why a dated log of each episode is useful.",
            sourceName: "Cleveland Clinic",
            sourceURL: cleveland
        ),
        DiscoverFact(
            id: "three-conditions",
            category: .basics,
            icon: "doc.on.doc.fill",
            title: "MCAS isn't the only mast cell condition",
            body: "The three main mast cell diseases are mastocytosis, MCAS, and hereditary alpha-tryptasemia. In MCAS the mast cells are overactive. In mastocytosis there are too many of them, which is a different problem that needs different testing.",
            sourceName: "Allergy & Asthma Network",
            sourceURL: aanDiseases
        ),
        DiscoverFact(
            id: "companions",
            category: .basics,
            icon: "link",
            title: "Often discussed alongside POTS and EDS",
            body: "In the medical literature, MCAS is often reported together with conditions like POTS (postural orthostatic tachycardia syndrome) and Ehlers-Danlos syndrome. Having one doesn't mean you have the others.",
            sourceName: "PubMed Central review",
            sourceURL: pmcComorbidity
        ),
        DiscoverFact(
            id: "triggers-vary",
            category: .triggers,
            icon: "thermometer.sun.fill",
            title: "Triggers are personal",
            body: "Commonly reported triggers include temperature changes, certain foods, alcohol, some medications, and allergens like pollen. But what sets off an episode differs a lot from person to person, which is why tracking your own patterns matters.",
            sourceName: "Allergy & Asthma Network",
            sourceURL: aanMCAS
        ),
        DiscoverFact(
            id: "diagnosis-debated",
            category: .diagnosis,
            icon: "puzzlepiece.fill",
            title: "Diagnosis is still debated",
            body: "Experts don't fully agree on how MCAS should be diagnosed. Many clinicians look for three things together: repeated episodes affecting two or more body systems, higher mast cell chemical levels measured during symptoms, and improvement with treatment aimed at mast cells.",
            sourceName: "Cleveland Clinic",
            sourceURL: cleveland
        ),
        DiscoverFact(
            id: "overlap",
            category: .diagnosis,
            icon: "stethoscope",
            title: "Symptoms overlap with other conditions",
            body: "Flushing, stomach problems, and dizziness show up in many conditions, not just MCAS. That's why it's important to have a clinician look at the whole picture instead of relying on symptoms alone.",
            sourceName: "Cleveland Clinic",
            sourceURL: cleveland
        ),
        DiscoverFact(
            id: "bring-log",
            category: .diagnosis,
            icon: "doc.text.fill",
            title: "Timing matters for testing",
            body: "Mast cell chemicals are most informative when measured during symptoms, so being able to tell your clinician when episodes happened, what came before, and what helped gives them useful context. The Doctor Summary on your Analytics tab is built for exactly this.",
            sourceName: "Allergy & Asthma Network",
            sourceURL: aanMCAS
        ),
        DiscoverFact(
            id: "treatments",
            category: .care,
            icon: "pills.fill",
            title: "Treatment targets mast cell chemicals",
            body: "Medication types doctors may use include H1 and H2 antihistamines, mast cell stabilizers (like cromolyn sodium), and leukotriene inhibitors (like montelukast), and some patients are evaluated for omalizumab. What's right depends on the person, so never start, stop, or change a medication without your doctor.",
            sourceName: "Allergy & Asthma Network",
            sourceURL: aanDiseases
        ),
        DiscoverFact(
            id: "anaphylaxis",
            category: .safety,
            icon: "exclamationmark.triangle.fill",
            title: "Know the emergency signs",
            body: "Trouble breathing, swelling of the throat or tongue, fainting, or a sudden drop in blood pressure can signal anaphylaxis, which is a medical emergency. Call 911 (in the U.S.) and follow any emergency plan your doctor has given you.",
            sourceName: "Allergy & Asthma Network",
            sourceURL: aanMCAS
        )
    ]

    static let articles: [DiscoverArticle] = [
        DiscoverArticle(
            id: "cleveland",
            source: "Cleveland Clinic",
            title: "Mast Cell Activation Syndrome (MCAS): Symptoms & Care",
            summary: "A plain-language overview of symptoms, diagnosis, and care, including where experts disagree.",
            url: cleveland
        ),
        DiscoverArticle(
            id: "aan-mcas",
            source: "Allergy & Asthma Network",
            title: "What is Mast Cell Activation Syndrome (MCAS)?",
            summary: "Symptoms, common triggers, and how diagnosis criteria work, from a patient education organization.",
            url: aanMCAS
        ),
        DiscoverArticle(
            id: "aan-diseases",
            source: "Allergy & Asthma Network",
            title: "What Are Mast Cell Diseases?",
            summary: "How MCAS compares with mastocytosis and hereditary alpha-tryptasemia, plus the medication types doctors may use.",
            url: aanDiseases
        ),
        DiscoverArticle(
            id: "merck",
            source: "Merck Manual, Professional Edition",
            title: "Mastocytosis and Mast Cell Activation Syndrome",
            summary: "A clinician-level reference. Handy to share with your doctor.",
            url: merck
        ),
        DiscoverArticle(
            id: "pmc-review",
            source: "PubMed Central (free to read)",
            title: "Diagnosis, Classification and Management of Mast Cell Activation Syndromes (MCAS) in the Era of Personalized Medicine",
            summary: "A medical review article on how MCAS is classified and diagnosed. Technical, but open access.",
            url: pmcReview
        )
    ]

    /// Changes once a day, and skips the safety card so the hero is never alarming.
    static func factOfTheDay(for date: Date = Date()) -> DiscoverFact {
        let pool = facts.filter { $0.category != .safety }
        let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 0
        return pool[day % pool.count]
    }
}