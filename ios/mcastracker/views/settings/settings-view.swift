import SwiftUI

/// Reached via the gear icon on Home, medications/frequency/
/// history are set once during onboarding and aren't editable here[cite: 11]
struct SettingsView: View {
    @EnvironmentObject private var profileStore: UserProfileStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var birthday = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    @State private var sex: BiologicalSex?
    @State private var city = ""
    @State private var state = usStates.first ?? "California"

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
    }

    private func save() {
        var profile = profileStore.profile ?? UserProfile()
        profile.name = name
        profile.birthday = birthday
        profile.age = Calendar.current.dateComponents([.year], from: birthday, to: Date()).year
        profile.sex = sex
        profile.city = city
        profile.state = state
        profileStore.save(profile)
        dismiss()
    }
}