import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var stats: DashboardStats?
    @Published var insights: InsightsResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadDashboard() async {
        isLoading = true
        errorMessage = nil

        var encounteredError = false

        do {
            stats = try await APIClient.shared.fetchDashboard()
        } catch {
            encounteredError = true
        }

        do {
            insights = try await APIClient.shared.fetchInsights()
        } catch {
            insights = nil  // clear stale data rather than leaving an outdated card on screen
            encounteredError = true
        }

        if encounteredError {
            errorMessage = "Couldn't load your dashboard. Pull down to try again."
        }

        isLoading = false
    }
}