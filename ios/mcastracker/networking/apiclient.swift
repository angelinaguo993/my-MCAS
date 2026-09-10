import Foundation

/// One place for every network call the app makes. Views/ViewModels call
/// these functions instead of using URLSession directly, so error handling
/// and JSON decoding stay consistent everywhere.
enum APIError: Error {
    case badResponse
    case decodingFailed
}

final class APIClient {
    static let shared = APIClient()
    private init() {}

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    /// Flow 1: dashboard's "days since last episode" card.
    func fetchDashboard() async throws -> DashboardStats {
        let (data, response) = try await URLSession.shared.data(from: Endpoints.dashboard)
        try validate(response)
        return try decoder.decode(DashboardStats.self, from: data)
    }

    /// Flow 2: submitting the episode survey.
    func submitEpisode(_ episode: Episode) async throws -> Episode {
        var request = URLRequest(url: Endpoints.episodes)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(episode)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response)
        return try decoder.decode(Episode.self, from: data)
    }

    /// Flow 3: calendar view — episodes for a given month.
    func fetchEpisodes(year: Int, month: Int) async throws -> [Episode] {
        let (data, response) = try await URLSession.shared.data(from: Endpoints.episodes(year: year, month: month))
        try validate(response)
        return try decoder.decode([Episode].self, from: data)
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.badResponse
        }
    }
}
