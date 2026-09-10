import SwiftUI

/// Core Flow 2: the structured survey covering triggers, symptoms, and
/// medication. Presented as a sheet from the dashboard's "Record Episode"
/// button.
struct EpisodeLogView: View {
    @StateObject private var viewModel = EpisodeLogViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        triggersSection
                        symptomsSection
                        overallSeveritySection
                        medicationSection
                        notesSection

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.footnote)
                                .foregroundColor(Theme.accent)
                        }

                        submitButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Record Episode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: viewModel.didSubmitSuccessfully) { _, didSucceed in
                if didSucceed { dismiss() }
            }
            .overlay {
                if viewModel.isSubmitting { LoadingView() }
            }
        }
    }

    // MARK: Triggers

    private var triggersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What might have triggered this?")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            FlowChips(
                items: Trigger.allCases,
                isSelected: { viewModel.selectedTriggers.contains($0) },
                label: { $0.displayName },
                onTap: { viewModel.toggleTrigger($0) }
            )
        }
        .cardStyle()
    }

    // MARK: Symptoms

    private var symptomsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What symptoms did you have?")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            FlowChips(
                items: SymptomCategory.allCases,
                isSelected: { viewModel.selectedSymptomCategories.contains($0) },
                label: { $0.displayName },
                onTap: { viewModel.toggleSymptom($0) }
            )

            // A severity slider appears for each symptom category the user selected,
            // since severity can differ a lot by system (e.g. mild skin, severe GI).
            ForEach(SymptomCategory.allCases.filter { viewModel.selectedSymptomCategories.contains($0) }) { category in
                SeverityPickerView(label: category.displayName, value: viewModel.severityBinding(for: category))
            }
        }
        .cardStyle()
    }

    // MARK: Overall severity

    private var overallSeveritySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Overall episode severity")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
            SeverityPickerView(label: "Overall", value: $viewModel.overallSeverity)
        }
        .cardStyle()
    }

    // MARK: Medication

    private var medicationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Took medication for this episode", isOn: $viewModel.medicationTaken)
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
                .tint(Theme.primary)

            if viewModel.medicationTaken {
                TextField("Medication name", text: $viewModel.medicationName)
                    .textFieldStyle(.roundedBorder)

                Toggle("Did it help?", isOn: $viewModel.medicationHelped)
                    .tint(Theme.success)
            }
        }
        .cardStyle()
    }

    // MARK: Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes (optional)")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
            TextEditor(text: $viewModel.notes)
                .frame(height: 80)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
        }
        .cardStyle()
    }

    private var submitButton: some View {
        Button {
            Task { await viewModel.submit() }
        } label: {
            Text("Save Episode")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.canSubmit ? Theme.accent : Color.gray)
                .cornerRadius(Theme.cardCornerRadius)
        }
        .disabled(!viewModel.canSubmit || viewModel.isSubmitting)
    }
}

/// Small reusable "chip" multi-select grid — used for both the triggers
/// list and the symptom-category list above.
private struct FlowChips<Item: Identifiable & Hashable>: View {
    let items: [Item]
    let isSelected: (Item) -> Bool
    let label: (Item) -> String
    let onTap: (Item) -> Void

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(items) { item in
                Button {
                    onTap(item)
                } label: {
                    Text(label(item))
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(isSelected(item) ? Theme.primary : Color.gray.opacity(0.12))
                        .foregroundColor(isSelected(item) ? .white : Theme.textPrimary)
                        .cornerRadius(10)
                }
            }
        }
    }
}

#Preview {
    EpisodeLogView()
}
