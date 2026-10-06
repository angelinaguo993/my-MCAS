import Foundation

// timeframe options
enum TrendTimeframe: String, CaseIterable, Identifiable {
    case oneWeek = "1 Week"
    case oneMonth = "1 Month"
    case threeMonths = "3 Months"
    var id: String { rawValue }
}

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var episodes: [Episode] = []
    @Published var trendEpisodes: [Episode] = [] // <-- Separate array so graphs don't mess up the calendar
    @Published var isLoading = false
    @Published var errorMessage: String?

    var episodesByDay: [Int: [Episode]] {
        let calendar = Calendar.current
        return Dictionary(grouping: episodes) { calendar.component(.day, from: $0.date) }
    }

    func loadMonth(year: Int, month: Int) async {
        isLoading = true
        errorMessage = nil
        do {
            episodes = try await APIClient.shared.fetchEpisodes(year: year, month: month)
        } catch {
            print("🚨 FETCH EPISODES ERROR: \(error)")
            errorMessage = "Couldn't load episode history."
        }
        isLoading = false
    }
    
    // function to handle multi-month fetching for trends
    func loadTrends(timeframe: TrendTimeframe) async {
        isLoading = true
        errorMessage = nil
        let calendar = Calendar.current
        let now = Date()
        var fetchedEpisodes: [Episode] = []
        
        do {
            // Fetch 3 months for the long view, or 2 months for shorter views (in case 1 week crosses a month boundary)
            let monthsToFetch = timeframe == .threeMonths ? 3 : 2
            
            for i in 0..<monthsToFetch {
                if let targetMonth = calendar.date(byAdding: .month, value: -i, to: now) {
                    let year = calendar.component(.year, from: targetMonth)
                    let month = calendar.component(.month, from: targetMonth)
                    let eps = try await APIClient.shared.fetchEpisodes(year: year, month: month)
                    fetchedEpisodes.append(contentsOf: eps)
                }
            }
            
            // Calculate the strict start date based on the user's toggle
            let startDate: Date
            switch timeframe {
            case .oneWeek:
                startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            case .oneMonth:
                startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            case .threeMonths:
                startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
            }
            
            // Deduplicate (in case the API returns overlaps) and filter to exact date range
            var seenIds = Set<String>()
            var deduplicated: [Episode] = []
            for ep in fetchedEpisodes {
                if !seenIds.contains(ep.id) {
                    seenIds.insert(ep.id)
                    deduplicated.append(ep)
                }
            }
            
            self.trendEpisodes = deduplicated
                .filter { $0.date >= startDate && $0.date <= now }
                .sorted { $0.date < $1.date }
            
        } catch {
            print("🚨 FETCH TRENDS ERROR: \(error)")
            errorMessage = "Couldn't load trend data."
        }
        isLoading = false
    }
}