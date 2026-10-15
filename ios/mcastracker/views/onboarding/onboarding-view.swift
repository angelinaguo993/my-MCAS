import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var profileStore: UserProfileStore
    @State private var currentStep = 0
    private let totalSteps = 5

    // 1. About You State
    @State private var name = ""
    @State private var birthday = Date()
    @State private var sex = "Prefer not to say"
    @State private var state = ""
    @State private var city = ""
    let sexOptions = ["Female", "Male", "Non-binary", "Other", "Prefer not to say"]

    // 2. Medications State & Custom Input
    @State private var prescribedMedications: Set<String> = []
    let baseMedicationOptions = ["Antihistamines", "Mast Cell Stabilizers", "Leukotriene Inhibitors", "H2 Blockers", "Corticosteroids"]
    @State private var customMedications: [String] = []
    @State private var newMedicationInput = ""

    // 3. Frequency State
    @State private var episodeFrequency = "Weekly"
    let frequencyOptions = ["Daily", "Weekly", "Monthly", "Rarely"]

    // 4. Symptoms State & Custom Input
    @State private var selectedSymptoms: Set<String> = []
    let baseSymptomOptions = ["Flushing", "Hives", "Itching", "Swelling (eyes, lips, tongue, throat)", "Nausea", "Vomiting", "Diarrhea", "Cramping", "Bloating", "Wheezing", "Shortness of Breath", "Dizziness", "Fainting", "Rapid Heartbeat", "Low Blood Pressure", "Anxiety", "Brain Fog", "Fatigue", "Stress"]
    @State private var customSymptoms: [String] = []
    @State private var newSymptomInput = ""

    // 5. Triggers State
    @State private var selectedTriggers: Set<String> = []
    let triggerOptions = ["High Histamine Food", "Lack of Sleep", "Stress", "Heat, Sun/Sunlight", "Exercise", "Alcohol", "Odors / Chemicals (perfumes, scents)", "Friction / Pressure", "Cold", "Drugs (NSAIDs, antibiotics, opioids, etc.)", "Venoms (insect stings, snake bites, spider bites, etc.)", "Allergies (pollen, dust, pet dander, etc.)", "Other"]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 20) {
                // Progress Bar Header
                progressBar

                // Multi-Slide Container
                TabView(selection: $currentStep) {
                    aboutYouSlide.tag(0)
                    medicationsSlide.tag(1)
                    frequencySlide.tag(2)
                    symptomsSlide.tag(3)
                    triggersSlide.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)

                // Navigation Footer
                navigationFooter
            }
            .padding()
        }
    }

    // MARK: - Slide 1: About You
    private var aboutYouSlide: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                slideHeader(title: "About You", subtitle: "Let's get to know you to personalize your tracker.")

                VStack(alignment: .leading, spacing: 6) {
                    Text("Name").font(.subheadline).foregroundColor(Theme.textPrimary)
                    TextField("Enter your name", text: $name)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Birthday").font(.subheadline).foregroundColor(Theme.textPrimary)
                    DatePicker("", selection: $birthday, displayedComponents: .date)
                        .datePickerStyle(.compact)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Sex").font(.subheadline).foregroundColor(Theme.textPrimary)
                    Picker("Sex", selection: $sex) {
                        ForEach(sexOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("State").font(.subheadline).foregroundColor(Theme.textPrimary)
                    TextField("e.g., California", text: $state)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("City").font(.subheadline).foregroundColor(Theme.textPrimary)
                    TextField("e.g., Los Angeles", text: $city)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
    }

    // MARK: - Slide 2: Medications Card
    private var medicationsSlide: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                slideHeader(title: "Prescribed Medications", subtitle: "Select any medications prescribed by your doctor.")
                
                selectableChipGrid(options: baseMedicationOptions + customMedications, selection: $prescribedMedications)
                
                HStack(spacing: 8) {
                    TextField("Add other medication", text: $newMedicationInput)
                        .textFieldStyle(.roundedBorder)
                    
                    Button {
                        let trimmed = newMedicationInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        if !baseMedicationOptions.contains(trimmed) && !customMedications.contains(trimmed) {
                            customMedications.append(trimmed)
                        }
                        prescribedMedications.insert(trimmed)
                        newMedicationInput = ""
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(Theme.accent)
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Slide 3: Frequency
    private var frequencySlide: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                slideHeader(title: "Episode Frequency", subtitle: "How often do you typically experience episodes?")
                
                VStack(spacing: 10) {
                    ForEach(frequencyOptions, id: \.self) { freq in
                        Button {
                            episodeFrequency = freq
                        } label: {
                            HStack {
                                Text(freq)
                                    .font(.body)
                                    .foregroundColor(episodeFrequency == freq ? .white : Theme.textPrimary)
                                Spacer()
                                if episodeFrequency == freq {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.white)
                                }
                            }
                            .padding()
                            .background(episodeFrequency == freq ? Theme.accent : Color.gray.opacity(0.15))
                            .cornerRadius(12)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Slide 4: Symptoms
    private var symptomsSlide: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                slideHeader(title: "Prior Symptoms", subtitle: "Select symptoms you have experienced before.")
                
                selectableChipGrid(options: baseSymptomOptions + customSymptoms, selection: $selectedSymptoms)
                
                HStack(spacing: 8) {
                    TextField("Add other symptom", text: $newSymptomInput)
                        .textFieldStyle(.roundedBorder)
                    
                    Button {
                        let trimmed = newSymptomInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        if !baseSymptomOptions.contains(trimmed) && !customSymptoms.contains(trimmed) {
                            customSymptoms.append(trimmed)
                        }
                        selectedSymptoms.insert(trimmed)
                        newSymptomInput = ""
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(Theme.accent)
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Slide 5: Triggers
    private var triggersSlide: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                slideHeader(title: "Prior Triggers", subtitle: "Select triggers you know affect you.")
                
                selectableChipGrid(options: triggerOptions, selection: $selectedTriggers)
            }
        }
    }

    // MARK: - Helper UI Components

    private func selectableChipGrid(options: [String], selection: Binding<Set<String>>) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
            ForEach(options, id: \.self) { option in
                let isSelected = selection.wrappedValue.contains(option)
                Button {
                    if isSelected {
                        selection.wrappedValue.remove(option)
                    } else {
                        selection.wrappedValue.insert(option)
                    }
                } label: {
                    Text(option)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isSelected ? Theme.accent : Color.gray.opacity(0.15))
                        .foregroundColor(isSelected ? .white : Theme.textPrimary)
                        .cornerRadius(20)
                }
            }
        }
    }

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep ? Theme.accent : Color.gray.opacity(0.3))
                    .frame(height: 6)
            }
        }
        .padding(.top, 8)
    }

    private func slideHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2.bold())
                .foregroundColor(Theme.textPrimary)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.bottom, 8)
    }

    private var navigationFooter: some View {
        HStack {
            if currentStep > 0 {
                Button {
                    withAnimation { currentStep -= 1 }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(Theme.textPrimary)
                }
            }

            Spacer()

            Button {
                if currentStep < totalSteps - 1 {
                    withAnimation { currentStep += 1 }
                } else {
                    completeOnboarding()
                }
            } label: {
                Text(currentStep == totalSteps - 1 ? "Get Started" : "Next")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(Theme.accent)
                    .cornerRadius(10)
            }
        }
        .padding(.vertical, 8)
    }

    private func completeOnboarding() {
        let mappedSex: BiologicalSex? = {
            switch sex {
                case "Female": return .female
                case "Male": return .male
                case "Intersex": return .intersex
                case "Prefer not to say": return .preferNotToSay
                default: return nil
            }
        }()

        let profile = UserProfile(
            name: name,
            birthday: birthday,
            sex: mappedSex,
            city: city,
            state: state,
            prescribedMedications: Array(prescribedMedications),
            previousSymptoms: SymptomCategory.allCases.filter { category in
                !Set(category.specificSymptoms.map { $0.lowercased() }).isDisjoint(with: Set(selectedSymptoms.map { $0.lowercased() }))
            },
            previousSpecificSymptoms: Array(selectedSymptoms.union(customSymptoms)),
            otherSymptomDescription: customSymptoms.isEmpty ? nil : customSymptoms.joined(separator: ", "),
            previousTriggers: selectedTriggers.compactMap { selected in
                switch selected {
                case "High Histamine Food": return .highHistamineFood
                case "Lack of Sleep": return .lackOfSleep
                case "Heat, Sun/Sunlight": return .heat
                case "Odors / Chemicals (perfumes, scents)": return .fragrance
                case "Friction / Pressure": return .friction
                case "Barometric pressure changes": return .barometricPressure
                case "Drugs (NSAIDs, antibiotics, opioids, etc.)": return .drugs
                case "Venoms (insect stings, snake bites, spider bites, etc.)": return .venoms
                case "Allergies (pollen, dust, pet dander, etc.)": return .allergies
                case "Other": return .other
                default: return Trigger.allCases.first { $0.displayName.localizedCaseInsensitiveContains(selected) }
                }
            },
            otherTriggerDescription: selectedTriggers.contains("Other") ? "Other trigger previously reported" : nil
        )
        
        profileStore.completeOnboarding(with: profile)
    }
}


