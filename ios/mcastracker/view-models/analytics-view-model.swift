import Foundation

@MainActor
final class AnalyticsViewModel: ObservableObject {
    // existing properties
    @Published var insights: InsightsResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // new AI properties
    @Published var aiResult: AIAnalysisResult?
    @Published var isAILoading = false
    private let aiService = AIAnalysisService()

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
    
    func generateAIInsights() async {
        isAILoading = true
        errorMessage = nil
        
        do {
            // 1. get the current year and month
            let now = Date()
            let calendar = Calendar.current
            let currentYear = calendar.component(.year, from: now)
            let currentMonth = calendar.component(.month, from: now)
            
            // 2. pass into the fetch method
            var episodes = try await APIClient.shared.fetchEpisodes(year: currentYear, month: currentMonth)
            if let previousMonthDate = calendar.date(byAdding: .month, value: -1, to: now) {
                let previous = try await APIClient.shared.fetchEpisodes(
                    year: calendar.component(.year, from: previousMonthDate),
                    month: calendar.component(.month, from: previousMonthDate)
                )
                let missingPreviousEpisodes = previous.filter { previousEpisode in
                    !episodes.contains(where: { $0.id == previousEpisode.id })
                }
                episodes.append(contentsOf: missingPreviousEpisodes)
            }
            
            // 3. send the episodes to OpenRouter
            let profile = UserDefaults.standard.data(forKey: "userProfile")
                .flatMap { try? JSONDecoder().decode(UserProfile.self, from: $0) }
            aiResult = try await aiService.fetchAnalysis(for: episodes, insights: insights, profile: profile)
        } catch {
            print("Decoding error: \(error)")
            errorMessage = "AI Analysis failed: \(error.localizedDescription)"
        }
        
        isAILoading = false
    }
}
