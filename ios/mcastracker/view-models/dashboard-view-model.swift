import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var stats: DashboardStats?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadDashboard() async {
        isLoading = true
        errorMessage = nil
        do {
            stats = try await APIClient.shared.fetchDashboard()
        } catch {
            errorMessage = "Couldn't load your dashboard. Pull down to try again."
        }
        isLoading = false
    }
}
