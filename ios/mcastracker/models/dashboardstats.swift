import Foundation

/// Mirrors the backend's DashboardResponse — powers the "days since last
/// episode" card on the dashboard.
struct DashboardStats: Codable {
    var daysSinceLastEpisode: Int?
    var lastEpisodeDate: Date?
    var totalEpisodesLogged: Int

    enum CodingKeys: String, CodingKey {
        case daysSinceLastEpisode = "days_since_last_episode"
        case lastEpisodeDate = "last_episode_date"
        case totalEpisodesLogged = "total_episodes_logged"
    }
}
