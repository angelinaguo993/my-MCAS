import SwiftUI

/// Shown once, the first time the app launches (before hasCompletedOnboarding
/// is true). Collects the basic profile fields plus medications, typical
/// episode frequency, and prior symptom/trigger history — this initial
/// history isn't logged as an "episode," it just seeds the user's profile
/// so the app has some context before they start logging for real.
struct OnboardingView: View {
    @EnvironmentObject private var profileStore: UserProfileStore

    @State private var name = ""
    @State private var ageText = ""
    @State private var sex: BiologicalSex?
    @State private var location = ""
    @State private var selectedMedications: Set<String> = []
    @State private var otherMedicationName = ""
    @State private var frequency: EpisodeFrequency?
    @State private var previousSymptoms: Set<SymptomCategory> = []
    @State private var previousTriggers: Set<Trigger> = []

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        basicInfoSection
                        medicationsSection
                        frequencySection
                        previousSymptomsSection
                        previousTriggersSection
                        getStartedButton
                    }
                    .padding()
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Welcome")
                .font(.largeTitle.bold())
                .foregroundColor(Theme.textPrimary)
            Text("A few quick questions to get your tracker set up.")
                .font(.subheadline)
                .foregroundColor(Theme.textPrimary.opacity(0.7))
        }
    }

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About You").font(.headline).foregroundColor(Theme.textPrimary)

            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)

            TextField("Age", text: $ageText)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)

            Text("Sex").font(.subheadline).foregroundColor(Theme.textPrimary)
            ChipGrid(
                items: BiologicalSex.allCases,
                isSelected: { sex == $0 },
                label: { $0.displayName },
                onTap: { sex = $0 }
            )

            TextField("Location (city, state)", text: $location)
                .textFieldStyle(.roundedBorder)
        }
        .cardStyle()
    }

    private var medicationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Medications prescribed by your doctor")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            ChipGrid(
                items: commonMedications,
                isSelected: { selectedMedications.contains($0) },
                label: { $0 },
                onTap: { toggleMedication($0) }
            )

            TextField("Other medication", text: $otherMedicationName)
                .textFieldStyle(.roundedBorder)
        }
        .cardStyle()
    }

    private var frequencySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How often do you typically have episodes?")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            ChipGrid(
                items: EpisodeFrequency.allCases,
                isSelected: { frequency == $0 },
                label: { $0.displayName },
                onTap: { frequency = $0 }
            )
        }
        .cardStyle()
    }

    private var previousSymptomsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Symptoms you've had before")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            ChipGrid(
                items: SymptomCategory.allCases,
                isSelected: { previousSymptoms.contains($0) },
                label: { $0.displayName },
                onTap: { toggleSymptom($0) }
            )
        }
        .cardStyle()
    }

    private var previousTriggersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Triggers you've had before")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            ChipGrid(
                items: Trigger.allCases,
                isSelected: { previousTriggers.contains($0) },
                label: { $0.displayName },
                onTap: { toggleTrigger($0) }
            )
        }
        .cardStyle()
    }

    private var getStartedButton: some View {
        Button {
            submit()
        } label: {
            Text("Get Started")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(name.isEmpty ? Color.gray : Theme.accent)
                .cornerRadius(Theme.cardCornerRadius)
        }
        .disabled(name.isEmpty)
    }

    private func toggleMedication(_ med: String) {
        if selectedMedications.contains(med) { selectedMedications.remove(med) }
        else { selectedMedications.insert(med) }
    }

    private func toggleSymptom(_ symptom: SymptomCategory) {
        if previousSymptoms.contains(symptom) { previousSymptoms.remove(symptom) }
        else { previousSymptoms.insert(symptom) }
    }

    private func toggleTrigger(_ trigger: Trigger) {
        if previousTriggers.contains(trigger) { previousTriggers.remove(trigger) }
        else { previousTriggers.insert(trigger) }
    }

    private func submit() {
        var medications = Array(selectedMedications)
        if !otherMedicationName.isEmpty { medications.append(otherMedicationName) }

        let profile = UserProfile(
            name: name,
            age: Int(ageText),
            sex: sex,
            location: location,
            prescribedMedications: medications,
            typicalEpisodeFrequency: frequency,
            previousSymptoms: Array(previousSymptoms),
            previousTriggers: Array(previousTriggers)
        )
        profileStore.completeOnboarding(with: profile)
    }
}

/// Generic reusable chip multi-select grid, shared by onboarding,
/// settings, and (going forward) anywhere else that needs one — this is
/// the same idea as the private FlowChips in episode-log-view.swift, just
/// made shareable across files instead of locked to that one screen.
struct ChipGrid<Item: Hashable>: View {
    let items: [Item]
    let isSelected: (Item) -> Bool
    let label: (Item) -> String
    let onTap: (Item) -> Void

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
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

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView().environmentObject(UserProfileStore())
    }
}
