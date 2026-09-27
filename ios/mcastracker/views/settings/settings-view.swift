import SwiftUI

/// Reached via the gear icon on Home. Only edits the basic profile
/// fields (name, age, sex, location) — medications/frequency/history
/// are set once during onboarding and aren't editable here.
struct SettingsView: View {
    @EnvironmentObject private var profileStore: UserProfileStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var ageText = ""
    @State private var sex: BiologicalSex?
    @State private var location = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Name").font(.subheadline).foregroundColor(Theme.textPrimary)
                            TextField("Name", text: $name)
                                .textFieldStyle(.roundedBorder)

                            Text("Age").font(.subheadline).foregroundColor(Theme.textPrimary)
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

                            Text("Location").font(.subheadline).foregroundColor(Theme.textPrimary)
                            TextField("Location (city, state)", text: $location)
                                .textFieldStyle(.roundedBorder)
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
        ageText = profile.age.map { String($0) } ?? ""
        sex = profile.sex
        location = profile.location
    }

    private func save() {
        var profile = profileStore.profile ?? UserProfile()
        profile.name = name
        profile.age = Int(ageText)
        profile.sex = sex
        profile.location = location
        profileStore.save(profile)
        dismiss()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView().environmentObject(UserProfileStore())
    }
}
