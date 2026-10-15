import SwiftUI

/// Profile details and tracked medications, presented from the Home screen.
struct SettingsView: View {
    private let defaultMedications = [
        "Antihistamines",
        "Mast Cell Stabilizers",
        "Leukotriene Inhibitors",
        "H2 Blockers",
        "Corticosteroids"
    ]

    @EnvironmentObject private var profileStore: UserProfileStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var birthday = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    @State private var sex: BiologicalSex?
    @State private var city = ""
    @State private var state = usStates.first ?? "California"
    @State private var medications: [String] = []
    @State private var newMedication = ""
    @State private var medicationError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Name").font(.nSubheadline).foregroundColor(Theme.textPrimary)
                            TextField("Name", text: $name)
                                .textFieldStyle(.roundedBorder)

                            Text("Birthday").font(.nSubheadline).foregroundColor(Theme.textPrimary)
                            DatePicker(
                                "Birthday",
                                selection: $birthday,
                                in: ...Date(),
                                displayedComponents: .date
                            )
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .tint(Theme.primary)

                            Text("Sex").font(.nSubheadline).foregroundColor(Theme.textPrimary)
                            ChoiceChips(
                                items: BiologicalSex.allCases,
                                isSelected: { sex == $0 },
                                label: { sexOption in
                                    if let display = (sexOption as AnyObject).displayName as? String {
                                        return display
                                    }
                                    return sexOption.rawValue.capitalized
                                },
                                onTap: { sex = $0 }
                            )

                            Text("City").font(.nSubheadline).foregroundColor(Theme.textPrimary)
                            TextField("City", text: $city)
                                .textFieldStyle(.roundedBorder)

                            Text("State").font(.nSubheadline).foregroundColor(Theme.textPrimary)
                            Picker("State", selection: $state) {
                                ForEach(usStates, id: \.self) { Text($0) }
                            }
                            .pickerStyle(.menu)
                            .tint(Theme.primary)
                        }
                        .cardStyle()

                        medicationsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear { loadCurrentProfile() }
        }
    }

    private func loadCurrentProfile() {
        guard let profile = profileStore.profile else { return }
        name = profile.name
        birthday = profile.birthday ?? birthday
        sex = profile.sex
        city = profile.city
        state = profile.state.isEmpty ? (usStates.first ?? "California") : profile.state
        medications = profile.prescribedMedications
    }

    private func save() {
        var profile = profileStore.profile ?? UserProfile()
        profile.name = name
        profile.birthday = birthday
        profile.age = Calendar.current.dateComponents([.year], from: birthday, to: Date()).year
        profile.sex = sex
        profile.city = city
        profile.state = state
        profile.prescribedMedications = medications
        profileStore.save(profile)
        dismiss()
    }

    private var medicationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tracked Medications")
                .font(.nHeadline)
                .foregroundColor(Theme.textPrimary)
            Text("Choose the medication types you want to track. You can also add a specific medication by name.")
                .font(.nCaption)
                .foregroundColor(Theme.textPrimary.opacity(0.75))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 135), spacing: 8)], spacing: 8) {
                ForEach(defaultMedications, id: \.self) { medication in
                    let isSelected = containsMedication(medication)
                    Button {
                        toggleMedication(medication)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            Text(medication)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 0)
                        }
                        .font(.nCaptionBold)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .padding(.horizontal, 10)
                        .background(isSelected ? Theme.primary : Color.gray.opacity(0.12))
                        .foregroundColor(isSelected ? .white : Theme.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(medication)
                    .accessibilityValue(isSelected ? "Tracked" : "Not tracked")
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }

            let customMedications = medications.filter { medication in
                !defaultMedications.contains(where: { $0.localizedCaseInsensitiveCompare(medication) == .orderedSame })
            }
            ForEach(customMedications, id: \.self) { medication in
                HStack(spacing: 12) {
                    Text(medication)
                        .font(.nSubheadline)
                        .foregroundColor(Theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    Button {
                        medications.removeAll { $0 == medication }
                    } label: {
                        Image(systemName: "minus.circle")
                            .font(.title3)
                            .foregroundColor(Theme.accent)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Remove \(medication)")
                }
                Divider()
            }

            HStack(spacing: 8) {
                TextField("Medication name", text: $newMedication)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.done)
                    .onSubmit(addMedication)
                    .onChange(of: newMedication) { _ in medicationError = nil }
                Button(action: addMedication) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(Theme.accent)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Add medication")
                .accessibilityHint("Adds the typed medication to your tracked list")
                    .disabled(newMedication.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            if let medicationError {
                Text(medicationError)
                    .font(.nCaption)
                    .foregroundColor(Theme.accent)
            }
        }
        .cardStyle()
    }

    private func addMedication() {
        let medication = newMedication.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !medication.isEmpty else { return }
        guard !medications.contains(where: { $0.localizedCaseInsensitiveCompare(medication) == .orderedSame }) else {
            medicationError = "That medication is already on your list."
            return
        }
        medicationError = nil
        medications.append(medication)
        newMedication = ""
    }

    private func containsMedication(_ name: String) -> Bool {
        medications.contains { $0.localizedCaseInsensitiveCompare(name) == .orderedSame }
    }

    private func toggleMedication(_ name: String) {
        if containsMedication(name) {
            medications.removeAll { $0.localizedCaseInsensitiveCompare(name) == .orderedSame }
        } else {
            medications.append(name)
        }
    }
}
