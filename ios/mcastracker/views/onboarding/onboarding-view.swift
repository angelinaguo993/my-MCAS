import SwiftUI

/// Shown once, the first time the app launches. Every question here is
/// required before "Get Started" becomes enabled — for the multi-select
/// sections (medications, symptoms, triggers) where a brand-new user
/// might genuinely have none yet, an explicit "None of these yet" option
/// counts as a valid answer instead of forcing a false selection.
struct OnboardingView: View {
    @EnvironmentObject private var profileStore: UserProfileStore

    @State private var name = ""
    @State private var age: Int?
    @State private var sex: BiologicalSex?
    @State private var city = ""
    @State private var state: String?

    @State private var selectedMedications: Set<String> = []
    @State private var customMedications: [String] = [""]
    @State private var noMedications = false

    @State private var frequency: EpisodeFrequency?
    @State private var otherFrequencyText = ""

    @State private var previousSymptoms: Set<SymptomCategory> = []
    @State private var specificSymptomsByCategory: [SymptomCategory: Set<String>] = [:]
    @State private var otherSymptomText = ""
    @State private var noPreviousSymptoms = false

    @State private var previousTriggers: Set<Trigger> = []
    @State private var otherTriggerText = ""
    @State private var noPreviousTriggers = false

    private let ageRange = Array(1...100)

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
            Text("Welcome!")
                .font(.largeTitle.bold())
                .foregroundColor(Theme.textPrimary)
            Text("A few quick questions to get your tracker set up. Please fill out all the questions to the best you can.")
                .font(.subheadline)
                .foregroundColor(Theme.textPrimary.opacity(0.7))
        }
    }

    // MARK: Basic info

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About You").font(.headline).foregroundColor(Theme.textPrimary)

            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)

            Text("Age").font(.subheadline).foregroundColor(Theme.textPrimary)
            Picker("Age", selection: $age) {
                Text("Select age").tag(Int?.none)
                ForEach(ageRange, id: \.self) { value in
                    Text("\(value)").tag(Int?(value))
                }
            }
            .pickerStyle(.menu)
            .tint(Theme.primary)

            Text("Sex").font(.subheadline).foregroundColor(Theme.textPrimary)
            ChipGrid(
                items: BiologicalSex.allCases,
                isSelected: { sex == $0 },
                label: { $0.displayName },
                onTap: { sex = $0 }
            )

            TextField("City", text: $city)
                .textFieldStyle(.roundedBorder)

            Text("State").font(.subheadline).foregroundColor(Theme.textPrimary)
            Picker("State", selection: $state) {
                Text("Select state").tag(String?.none)
                ForEach(usStates, id: \.self) { name in
                    Text(name).tag(String?(name))
                }
            }
            .pickerStyle(.menu)
            .tint(Theme.primary)
        }
        .cardStyle()
    }

    // MARK: Medications

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

            ForEach(customMedications.indices, id: \.self) { index in
                TextField("Other medication", text: $customMedications[index])
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: customMedications[index]) { _ in
                        if !customMedications[index].isEmpty { noMedications = false }
                    }
            }

            Button {
                customMedications.append("")
            } label: {
                Label("Add another medication", systemImage: "plus.circle.fill")
                    .font(.caption.bold())
                    .foregroundColor(Theme.primary)
            }

            noneToggleButton(
                label: "I'm not currently on any medications",
                isOn: $noMedications
            ) {
                selectedMedications.removeAll()
                customMedications = [""]
            }
        }
        .cardStyle()
    }

    // MARK: Frequency

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

            if frequency == .other {
                TextField("Describe how often", text: $otherFrequencyText)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .cardStyle()
    }

    // MARK: Previous symptoms — expands into the specific-symptom checklist,
    // same as the real episode-logging screen.

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

            ForEach(SymptomCategory.allCases.filter { previousSymptoms.contains($0) }) { category in
                if category == .other {
                    TextField("Describe the symptom", text: $otherSymptomText)
                        .textFieldStyle(.roundedBorder)
                } else {
                    specificSymptomChecklist(for: category)
                }
            }

            noneToggleButton(
                label: "I haven't had any symptoms yet",
                isOn: $noPreviousSymptoms
            ) {
                previousSymptoms.removeAll()
                specificSymptomsByCategory.removeAll()
                otherSymptomText = ""
            }
        }
        .cardStyle()
    }

    private func specificSymptomChecklist(for category: SymptomCategory) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(category.specificSymptoms, id: \.self) { symptom in
                Button {
                    toggleSpecificSymptom(symptom, in: category)
                } label: {
                    HStack {
                        Image(systemName: isSpecificSymptomSelected(symptom, in: category)
                              ? "checkmark.square.fill" : "square")
                            .foregroundColor(isSpecificSymptomSelected(symptom, in: category)
                                             ? Theme.primary : .gray)
                        Text(symptom)
                            .font(.subheadline)
                            .foregroundColor(Theme.textPrimary)
                        Spacer()
                    }
                }
            }
        }
        .padding(.leading, 4)
    }

    // MARK: Previous triggers

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

            if previousTriggers.contains(.other) {
                TextField("Describe the trigger", text: $otherTriggerText)
                    .textFieldStyle(.roundedBorder)
            }

            noneToggleButton(
                label: "I haven't had any triggers yet",
                isOn: $noPreviousTriggers
            ) {
                previousTriggers.removeAll()
                otherTriggerText = ""
            }
        }
        .cardStyle()
    }

    // MARK: Shared "none of these" toggle row

    private func noneToggleButton(label: String, isOn: Binding<Bool>, onEnable: @escaping () -> Void) -> some View {
        Button {
            isOn.wrappedValue.toggle()
            if isOn.wrappedValue { onEnable() }
        } label: {
            HStack {
                Image(systemName: isOn.wrappedValue ? "checkmark.square.fill" : "square")
                    .foregroundColor(isOn.wrappedValue ? Theme.primary : .gray)
                Text(label)
                    .font(.caption)
                    .foregroundColor(Theme.textPrimary.opacity(0.8))
                Spacer()
            }
        }
        .padding(.top, 4)
    }

    // MARK: Validation

    private var canSubmit: Bool {
        guard !name.isEmpty else { return false }
        guard age != nil else { return false }
        guard sex != nil else { return false }
        guard !city.isEmpty else { return false }
        guard state != nil else { return false }

        let hasMedicationAnswer = noMedications
            || !selectedMedications.isEmpty
            || customMedications.contains { !$0.isEmpty }
        guard hasMedicationAnswer else { return false }

        guard frequency != nil else { return false }
        if frequency == .other, otherFrequencyText.isEmpty { return false }

        let hasSymptomAnswer = noPreviousSymptoms || !previousSymptoms.isEmpty
        guard hasSymptomAnswer else { return false }
        if previousSymptoms.contains(.other), otherSymptomText.isEmpty { return false }

        let hasTriggerAnswer = noPreviousTriggers || !previousTriggers.isEmpty
        guard hasTriggerAnswer else { return false }
        if previousTriggers.contains(.other), otherTriggerText.isEmpty { return false }

        return true
    }

    private var getStartedButton: some View {
        VStack(spacing: 6) {
            Button {
                submit()
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canSubmit ? Theme.accent : Color.gray)
                    .cornerRadius(Theme.cardCornerRadius)
            }
            .disabled(!canSubmit)

            if !canSubmit {
                Text("Please answer every question above to continue.")
                    .font(.caption)
                    .foregroundColor(Theme.textPrimary.opacity(0.5))
            }
        }
    }

    // MARK: Toggle helpers

    private func toggleMedication(_ med: String) {
        if selectedMedications.contains(med) { selectedMedications.remove(med) }
        else { selectedMedications.insert(med); noMedications = false }
    }

    private func toggleSymptom(_ symptom: SymptomCategory) {
        if previousSymptoms.contains(symptom) {
            previousSymptoms.remove(symptom)
            specificSymptomsByCategory[symptom] = nil
        } else {
            previousSymptoms.insert(symptom)
            noPreviousSymptoms = false
        }
    }

    private func toggleSpecificSymptom(_ symptom: String, in category: SymptomCategory) {
        var current = specificSymptomsByCategory[category] ?? []
        if current.contains(symptom) { current.remove(symptom) }
        else { current.insert(symptom) }
        specificSymptomsByCategory[category] = current
    }

    private func isSpecificSymptomSelected(_ symptom: String, in category: SymptomCategory) -> Bool {
        specificSymptomsByCategory[category]?.contains(symptom) ?? false
    }

    private func toggleTrigger(_ trigger: Trigger) {
        if previousTriggers.contains(trigger) { previousTriggers.remove(trigger) }
        else { previousTriggers.insert(trigger); noPreviousTriggers = false }
    }

    private func submit() {
        var medications = Array(selectedMedications)
        medications.append(contentsOf: customMedications.filter { !$0.isEmpty })

        let allSpecificSymptoms = specificSymptomsByCategory.values.flatMap { $0 }

        let profile = UserProfile(
            name: name,
            age: age,
            sex: sex,
            city: city,
            state: state ?? "",
            prescribedMedications: medications,
            typicalEpisodeFrequency: frequency,
            otherFrequencyDescription: frequency == .other ? otherFrequencyText : nil,
            previousSymptoms: Array(previousSymptoms),
            previousSpecificSymptoms: Array(allSpecificSymptoms),
            otherSymptomDescription: previousSymptoms.contains(.other) ? otherSymptomText : nil,
            previousTriggers: Array(previousTriggers),
            otherTriggerDescription: previousTriggers.contains(.other) ? otherTriggerText : nil
        )
        profileStore.completeOnboarding(with: profile)
    }
}

/// Generic reusable chip multi-select grid, shared across onboarding and settings.
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