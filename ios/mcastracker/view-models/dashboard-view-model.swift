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
        defer { isLoading = false }

        var encounteredError = false

        do {
            stats = try await APIClient.shared.fetchDashboard()
        } catch {
            if isCancellation(error) { return }
            print("DASHBOARD FETCH FAILED:", error)
            encounteredError = true
        }

        do {
            insights = try await APIClient.shared.fetchInsights()
        } catch {
            if isCancellation(error) { return }
            print("INSIGHTS FETCH FAILED:", error)
            insights = nil
            encounteredError = true
        }

        if encounteredError {
            errorMessage = "Couldn't load your dashboard. Pull down to try again."
        }
    }

    /// A request cancelled because its screen was rebuilt isn't a real failure.
    private func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        return (error as? URLError)?.code == .cancelled
    }
}