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
        do {
            // Fetch both at once rather than one after another, so the
            // dashboard doesn't wait twice as long to appear.
            async let statsResult = APIClient.shared.fetchDashboard()
            async let insightsResult = APIClient.shared.fetchInsights()
            stats = try await statsResult
            insights = try await insightsResult
        } catch {
            errorMessage = "Couldn't load your dashboard. Pull down to try again."
        }
        isLoading = false
    }
}