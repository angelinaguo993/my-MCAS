import Foundation

/// stores user profile and onboarding completion in UserDefaults, can access anywhere in the app
@MainActor
final class UserProfileStore: ObservableObject {
    @Published var profile: UserProfile?
    @Published var hasCompletedOnboarding: Bool

    private let profileKey = "userProfile"
    private let onboardingKey = "hasCompletedOnboarding"

    init() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            profile = decoded
        }
    }

    /// save new edits to existing profile.
    func save(_ profile: UserProfile) {
        self.profile = profile
        persist(profile)
    }

    /// used once when onboarding survey is submitted
    func completeOnboarding(with profile: UserProfile) {
        self.profile = profile
        persist(profile)
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: onboardingKey)
    }

    private func persist(_ profile: UserProfile) {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: profileKey)
        }
    }

    /// automatically adds a medication to the profile's list if it isn't already tracked
    func registerMedicationIfNeeded(_ medication: String) {
        let trimmed = medication.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, var currentProfile = profile else { return }
        
        if !currentProfile.prescribedMedications.contains(trimmed) {
            currentProfile.prescribedMedications.append(trimmed)
            save(currentProfile)
        }
    }
}
