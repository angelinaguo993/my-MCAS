import Foundation
import SwiftUI

@MainActor
final class EpisodeLogViewModel: ObservableObject {
    @Published var selectedTriggers: Set<Trigger> = []
    @Published var selectedSymptomCategories: Set<SymptomCategory> = []
    @Published var symptomSeverities: [SymptomCategory: Int] = [:]
    @Published var overallSeverity: Int = 5
    @Published var medicationTaken: Bool = false
    @Published var medicationName: String = ""
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
        } else {
            selectedSymptomCategories.insert(category)
            symptomSeverities[category] = 5 // sensible default
        }
    }

    func severityBinding(for category: SymptomCategory) -> Binding<Int> {
        Binding(
            get: { self.symptomSeverities[category] ?? 5 },
            set: { self.symptomSeverities[category] = $0 }
        )
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
            SymptomEntry(category: category, severity: symptomSeverities[category] ?? 5)
        }

        let episode = Episode(
            date: Date(),
            triggers: Array(selectedTriggers),
            symptoms: symptoms,
            overallSeverity: overallSeverity,
            medicationTaken: medicationTaken,
            medicationName: medicationTaken ? medicationName : nil,
            medicationHelped: medicationTaken ? medicationHelped : nil,
            notes: notes.isEmpty ? nil : notes
        )

        do {
            _ = try await APIClient.shared.submitEpisode(episode)
            didSubmitSuccessfully = true
        } catch {
            errorMessage = "Couldn't save this episode. Check your connection and try again."
        }

        isSubmitting = false
    }
}
