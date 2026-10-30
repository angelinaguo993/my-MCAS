import SwiftUI

/// shown when user taps on single episode in calendar day list
struct EpisodeDetailView: View {
    let episode: Episode
    var onDelete: (Episode) -> Void = { _ in }
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingDelete = false
    @State private var isDeleting = false
    @State private var deleteError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        summaryCard
                        triggersCard
                        symptomsCard
                        medicationCard
                        if let notes = episode.notes, !notes.isEmpty {
                            notesCard(notes)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(episode.date.formatted(date: .abbreviated, time: .shortened))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(role: .destructive) {
                        confirmingDelete = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .disabled(isDeleting || Int(episode.id) == nil)
                    .accessibilityLabel("Delete episode")
                }
            }
            .confirmationDialog(
                "Delete this episode?",
                isPresented: $confirmingDelete,
                titleVisibility: .visible
            ) {
                Button("Delete Episode", role: .destructive, action: deleteEpisode)
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This permanently removes the episode from your history.")
            }
            .alert("Couldn't delete episode", isPresented: Binding(
                get: { deleteError != nil },
                set: { if !$0 { deleteError = nil } }
            )) {
                Button("OK", role: .cancel) { deleteError = nil }
            } message: {
                Text(deleteError ?? "Please try again.")
            }
        }
    }

    private func deleteEpisode() {
        isDeleting = true
        Task { @MainActor in
            do {
                try await APIClient.shared.deleteEpisode(id: episode.id)
                onDelete(episode)
                dismiss()
            } catch {
                deleteError = "Your episode is still in history. Check your connection and try again."
            }
            isDeleting = false
        }
    }

    private var summaryCard: some View {
        HStack {
            Text("Overall severity")
                .font(.nHeadline)
                .foregroundColor(Theme.textPrimary)
            Spacer()
            Text("\(episode.overallSeverity)/10")
                .font(.nHeadline)
                .foregroundColor(Theme.accent)
        }
        .cardStyle()
    }

    private var triggersCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Triggers")
                .font(.nHeadline)
                .foregroundColor(Theme.textPrimary)
            if episode.triggers.isEmpty {
                Text("None recorded").font(.nSubheadline).foregroundColor(.gray)
            } else {
                ForEach(episode.triggers) { trigger in
                    Text("• \(trigger.displayName)").font(.nSubheadline)
                }
            }
        }
        .cardStyle()
    }

    private var symptomsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Symptoms")
                .font(.nHeadline)
                .foregroundColor(Theme.textPrimary)
            ForEach(episode.symptoms) { symptom in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(symptom.category.displayName).font(.nSubheadline)
                        Spacer()
                        Text("\(symptom.severity)/10")
                            .font(.nSubheadlineBold)
                            .foregroundColor(Theme.accent)
                    }
                    if !symptom.specificSymptoms.isEmpty {
                        Text(symptom.specificSymptoms.joined(separator: ", "))
                            .font(.nCaption)
                            .foregroundColor(Theme.textPrimary.opacity(0.6))
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .cardStyle()
    }

    private var medicationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Medication")
                .font(.nHeadline)
                .foregroundColor(Theme.textPrimary)
            if episode.medicationTaken {
                Text(episode.medicationNames.isEmpty ? "Taken" : episode.medicationNames.joined(separator: ", "))
                    .font(.nSubheadline)
                if let helped = episode.medicationHelped {
                    Text(helped ? "Helped" : "Didn't help")
                        .font(.nSubheadline)
                        .foregroundColor(helped ? Theme.success : Theme.accent)
                }
            } else {
                Text("None taken").font(.nSubheadline).foregroundColor(.gray)
            }
        }
        .cardStyle()
    }

    private func notesCard(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.nHeadline)
                .foregroundColor(Theme.textPrimary)
            Text(notes).font(.nSubheadline)
        }
        .cardStyle()
    }
}

struct EpisodeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        EpisodeDetailView(episode: Episode(
            id: UUID().uuidString,
            triggers: [.stress, .highHistamineFood],
            symptoms: [SymptomEntry(category: .gi, severity: 6)],
            overallSeverity: 6
        ))
    }
}
