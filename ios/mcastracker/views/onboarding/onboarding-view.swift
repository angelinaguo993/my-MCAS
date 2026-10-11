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
    
    // 2. Medications State
    @State private var selectedMedications: Set<String> = []
    let availableMedications = ["Antihistamines", "Mast Cell Stabilizers", "Leukotriene Inhibitors", "H2 Blockers", "Corticosteroids"]

    // 3. Frequency State
    @State private var episodeFrequency = "Weekly"
    let frequencies = ["Daily", "Weekly", "Monthly", "Rarely"]

    // 4. Symptoms State
    @State private var selectedSymptoms: Set<String> = []
    let availableSymptoms = ["Flushing", "Hives", "Itching", "Brain Fog", "Fatigue", "Abdominal Pain", "Nausea", "Headache", "Tachycardia"]

    // 5. Triggers State
    @State private var selectedTriggers: Set<Trigger> = []

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 20) {
                // Progress Bar at the Top
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

                // Bottom Navigation Arrows / Buttons
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
                        ForEach(["Female", "Male", "Non-binary", "Other", "Prefer not to say"], id: \.self) { option in
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
                
                ChipGrid(items: availableMedications, selectedItems: $selectedMedications)
            }
        }
    }

    // MARK: - Slide 3: Frequency
    private var frequencySlide: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                slideHeader(title: "Episode Frequency", subtitle: "How often do you typically experience episodes?")
                
                Picker("Frequency", selection: $episodeFrequency) {
                    ForEach(frequencies, id: \.self) { freq in
                        Text(freq).tag(freq)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 160)
            }
        }
    }

    // MARK: - Slide 4: Symptoms
    private var symptomsSlide: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                slideHeader(title: "Prior Symptoms", subtitle: "Select symptoms you have experienced before.")
                
                ChipGrid(items: availableSymptoms, selectedItems: $selectedSymptoms)
            }
        }
    }

    // MARK: - Slide 5: Triggers
    private var triggersSlide: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                slideHeader(title: "Prior Triggers", subtitle: "Select triggers you know affect you.")
                
                ChipGrid(
                    items: Trigger.allCases,
                    selectedItems: $selectedTriggers,
                    titleKeyPath: { $0.displayName }
                )
            }
        }
    }

    // MARK: - UI Components

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
        // Save profile logic here
    }
}