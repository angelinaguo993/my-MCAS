import SwiftUI

/// Shown when the user taps a day on the calendar with a logged episode.
struct EpisodeDetailView: View {
    let episode: Episode
    @Environment(\.dismiss) private var dismiss

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
            }
        }
    }

    private var summaryCard: some View {
        HStack {
            Text("Overall severity")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
            Spacer()
            Text("\(episode.overallSeverity)/10")
                .font(.headline)
                .foregroundColor(Theme.accent)
        }
        .cardStyle()
    }

    private var triggersCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Triggers")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
            if episode.triggers.isEmpty {
                Text("None recorded").font(.subheadline).foregroundColor(.gray)
            } else {
                ForEach(episode.triggers) { trigger in
                    Text("• \(trigger.displayName)").font(.subheadline)
                }
            }
        }
        .cardStyle()
    }

    private var symptomsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Symptoms")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
            ForEach(episode.symptoms) { symptom in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(symptom.category.displayName).font(.subheadline)
                        Spacer()
                        Text("\(symptom.severity)/10")
                            .font(.subheadline.bold())
                            .foregroundColor(Theme.accent)
                    }
                    if !symptom.specificSymptoms.isEmpty {
                        Text(symptom.specificSymptoms.joined(separator: ", "))
                            .font(.caption)
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
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
            if episode.medicationTaken {
                Text(episode.medicationNames.isEmpty ? "Taken" : episode.medicationNames.joined(separator: ", "))
                    .font(.subheadline)
                if let helped = episode.medicationHelped {
                    Text(helped ? "Helped" : "Didn't help")
                        .font(.subheadline)
                        .foregroundColor(helped ? Theme.success : Theme.accent)
                }
            } else {
                Text("None taken").font(.subheadline).foregroundColor(.gray)
            }
        }
        .cardStyle()
    }

    private func notesCard(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
            Text(notes).font(.subheadline)
        }
        .cardStyle()
    }
}

struct EpisodeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        EpisodeDetailView(episode: Episode(
            id: 1,
            triggers: [.stress, .highHistamineFood],
            symptoms: [SymptomEntry(category: .gi, severity: 6)],
            overallSeverity: 6
        ))
    }
}