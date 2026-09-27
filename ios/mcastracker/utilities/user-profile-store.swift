import Foundation

/// Holds the user's profile in memory and persists it to UserDefaults as
/// JSON. This app has no accounts/login, so "the user" just means
/// whoever has this device — one profile per install, stored locally
/// only. (Not synced to the backend; the backend's episode data has no
/// concept of "whose" episodes they are, since there's only ever one
/// user per install.)
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

    /// Used by Settings to save edits to an existing profile.
    func save(_ profile: UserProfile) {
        self.profile = profile
        persist(profile)
    }

    /// Used once, when the onboarding survey is submitted.
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
}
