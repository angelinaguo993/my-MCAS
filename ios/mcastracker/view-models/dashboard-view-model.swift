import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var stats: DashboardStats?
    @Published var insights: InsightsResponse?
    @Published var isLoading = false
    @Published var statsErrorMessage: String?
    @Published var insightsErrorMessage: String?
    @Published var statsUpdatedAt: Date?
    @Published var insightsUpdatedAt: Date?

    func loadDashboard() async {
        isLoading = true
        defer { isLoading = false }

        async let statsLoad: Void = loadStats()
        async let insightsLoad: Void = loadInsights()
        _ = await (statsLoad, insightsLoad)
    }

    func loadStats() async {
        do {
            stats = try await APIClient.shared.fetchDashboard()
            statsUpdatedAt = Date()
            statsErrorMessage = nil
        } catch {
            if isCancellation(error) { return }
            statsErrorMessage = stats == nil
                ? "Episode totals are unavailable right now."
                : "Couldn’t refresh episode totals. Showing the last loaded values."
        }
    }

    func loadInsights() async {
        do {
            insights = try await APIClient.shared.fetchInsights()
            insightsUpdatedAt = Date()
            insightsErrorMessage = nil
        } catch {
            if isCancellation(error) { return }
            insightsErrorMessage = insights == nil
                ? "Medication patterns are unavailable right now."
                : "Couldn’t refresh medication patterns. Showing the last loaded values."
        }
    }

    private func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        return (error as? URLError)?.code == .cancelled
    }
}
