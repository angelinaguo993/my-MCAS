import Foundation

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var episodes: [Episode] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// Episode dates for the visible month, keyed by day-of-month, so the
    /// calendar grid can quickly check "does this day have an episode?"
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
            errorMessage = "Couldn't load episode history."
        }
        isLoading = false
    }
}
