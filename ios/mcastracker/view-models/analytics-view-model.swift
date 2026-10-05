import Foundation

@MainActor
final class AnalyticsViewModel: ObservableObject {
    // Existing properties
    @Published var insights: InsightsResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // New AI properties
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
            // 1. Get the current year and month
            let now = Date()
            let calendar = Calendar.current
            let currentYear = calendar.component(.year, from: now)
            let currentMonth = calendar.component(.month, from: now)
            
            // 2. Pass them into the fetch method
            let episodes = try await APIClient.shared.fetchEpisodes(year: currentYear, month: currentMonth) 
            
            // 3. Send the episodes to OpenRouter
            aiResult = try await aiService.fetchAnalysis(for: episodes)
        } catch {
            print("Decoding error: \(error)")
            errorMessage = "AI Analysis failed: \(error.localizedDescription)"
        }
        
        isAILoading = false
    }
}