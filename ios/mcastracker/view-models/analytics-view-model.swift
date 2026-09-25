import Foundation

@MainActor
final class AnalyticsViewModel: ObservableObject {
    @Published var insights: InsightsResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadInsights() async {
        isLoading = true
        errorMessage = nil
        do {
            insights = try await APIClient.shared.fetchInsights()
        } catch {
            insights = nil
            errorMessage = "Couldn't load your analytics. Pull down to try again."
        }
        isLoading = false
    }
}
