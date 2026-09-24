import Foundation
import SwiftUI

@MainActor
final class EpisodeLogViewModel: ObservableObject {
    @Published var selectedTriggers: Set<Trigger> = []
    @Published var otherTriggerDescription: String = ""
    @Published var selectedSymptomCategories: Set<SymptomCategory> = []
    @Published var symptomSeverities: [SymptomCategory: Int] = [:]
    @Published var specificSymptoms: [SymptomCategory: Set<String>] = [:]
    @Published var overallSeverity: Int = 5
    @Published var medicationTaken: Bool = false
    @Published var selectedMedications: Set<String> = []
    @Published var otherMedicationName: String = ""
    @Published var medicationHelped: Bool = false
    @Published var notes: String = ""

    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var didSubmitSuccessfully = false

    func toggleTrigger(_ trigger: Trigger) {
        if selectedTriggers.contains(trigger) {
            selectedTriggers.remove(trigger)
        } else {
            selectedTriggers.insert(trigger)
        }
    }

    func toggleSymptom(_ category: SymptomCategory) {
        if selectedSymptomCategories.contains(category) {
            selectedSymptomCategories.remove(category)
            symptomSeverities[category] = nil
            specificSymptoms[category] = nil
        } else {
            selectedSymptomCategories.insert(category)
            symptomSeverities[category] = 5 // sensible default
        }
    }

    /// Checks/unchecks one specific symptom (e.g. "Hives") within a category.
    func toggleSpecificSymptom(_ symptom: String, in category: SymptomCategory) {
        var current = specificSymptoms[category] ?? []
        if current.contains(symptom) {
            current.remove(symptom)
        } else {
            current.insert(symptom)
        }
        specificSymptoms[category] = current
    }

    func isSpecificSymptomSelected(_ symptom: String, in category: SymptomCategory) -> Bool {
        specificSymptoms[category]?.contains(symptom) ?? false
    }

    func severityBinding(for category: SymptomCategory) -> Binding<Int> {
        Binding(
            get: { self.symptomSeverities[category] ?? 5 },
            set: { self.symptomSeverities[category] = $0 }
        )
    }

    /// For category .other, reuses the same specificSymptoms storage to hold
    /// one free-typed description instead of a checked list from a fixed set.
    func otherSymptomDescriptionBinding() -> Binding<String> {
        Binding(
            get: { self.specificSymptoms[.other]?.first ?? "" },
            set: { self.specificSymptoms[.other] = $0.isEmpty ? [] : [$0] }
        )
    }

    func toggleMedication(_ medication: String) {
        if selectedMedications.contains(medication) {
            selectedMedications.remove(medication)
        } else {
            selectedMedications.insert(medication)
        }
    }

    var canSubmit: Bool {
        !selectedSymptomCategories.isEmpty
    }

    func submit() async {
        guard canSubmit else {
            errorMessage = "Log at least one symptom before saving."
            return
        }

        isSubmitting = true
        errorMessage = nil

        let symptoms = selectedSymptomCategories.map { category in
            SymptomEntry(
                category: category,
                severity: symptomSeverities[category] ?? 5,
                specificSymptoms: Array(specificSymptoms[category] ?? [])
            )
        }

        var combinedNotes = notes
        if selectedTriggers.contains(.other), !otherTriggerDescription.isEmpty {
            let triggerNote = "Other trigger: \(otherTriggerDescription)"
            combinedNotes = combinedNotes.isEmpty ? triggerNote : "\(combinedNotes)\n\(triggerNote)"
        }

        var medicationNames = Array(selectedMedications)
        if !otherMedicationName.isEmpty {
            medicationNames.append(otherMedicationName)
        }

        let episode = Episode(
            date: Date(),
            triggers: Array(selectedTriggers),
            symptoms: symptoms,
            overallSeverity: overallSeverity,
            medicationTaken: medicationTaken,
            medicationNames: medicationTaken ? medicationNames : [],
            medicationHelped: medicationTaken ? medicationHelped : nil,
            notes: combinedNotes.isEmpty ? nil : combinedNotes
        )

        do {
            _ = try await APIClient.shared.submitEpisode(episode)
            didSubmitSuccessfully = true
        } catch {
            print("SUBMIT EPISODE FAILED:", error)  // TEMP DEBUG — check Xcode console for this
            errorMessage = "Couldn't save this episode. Check your connection and try again."
        }

        isSubmitting = false
    }
}