import Foundation

/// One place for every network call the app makes. Views/ViewModels call
/// these functions instead of using URLSession directly, so error handling
/// and JSON decoding stay consistent everywhere.
enum APIError: Error, LocalizedError {
    case badResponse(statusCode: Int, body: String)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .badResponse(let statusCode, let body):
            return "Server returned \(statusCode): \(body)"
        case .decodingFailed:
            return "Failed to decode response"
        }
    }
}

final class APIClient {
    static let shared = APIClient()

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 90
        session = URLSession(configuration: config)
    }

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            let isoWithFraction = ISO8601DateFormatter()
            isoWithFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoWithFraction.date(from: dateString) { return date }

            let iso = ISO8601DateFormatter()
            if let date = iso.date(from: dateString) { return date }

            let pythonWithMicroseconds = DateFormatter()
            pythonWithMicroseconds.locale = Locale(identifier: "en_US_POSIX")
            pythonWithMicroseconds.timeZone = TimeZone(identifier: "UTC")
            pythonWithMicroseconds.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
            if let date = pythonWithMicroseconds.date(from: dateString) { return date }

            let pythonNoFraction = DateFormatter()
            pythonNoFraction.locale = Locale(identifier: "en_US_POSIX")
            pythonNoFraction.timeZone = TimeZone(identifier: "UTC")
            pythonNoFraction.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            if let date = pythonNoFraction.date(from: dateString) { return date }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unrecognized date format: \(dateString)"
            )
        }
        return d
    }()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    /// Flow 1: dashboard's "days since last episode" card.
    func fetchDashboard() async throws -> DashboardStats {
        let (data, response) = try await session.data(from: Endpoints.dashboard)
        try validate(response, data)
        return try decoder.decode(DashboardStats.self, from: data)
    }

    /// Flow 2: submitting the episode survey.
    func submitEpisode(_ episode: Episode) async throws -> Episode {
        var request = URLRequest(url: Endpoints.episodes)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(episode)

        let (data, response) = try await session.data(for: request)
        try validate(response, data)
        return try decoder.decode(Episode.self, from: data)
    }

    /// Flow 3: calendar view — episodes for a given month.
    func fetchEpisodes(year: Int, month: Int) async throws -> [Episode] {
        let (data, response) = try await session.data(from: Endpoints.episodes(year: year, month: month))
        try validate(response, data)
        return try decoder.decode([Episode].self, from: data)
    }

    /// Dashboard's trigger/symptom/medication summary cards.
    func fetchInsights() async throws -> InsightsResponse {
        let (data, response) = try await session.data(from: Endpoints.insights)
        try validate(response, data)
        return try decoder.decode(InsightsResponse.self, from: data)
    }

    private func validate(_ response: URLResponse, _ data: Data) throws {
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            let body = String(data: data, encoding: .utf8) ?? "(no body)"
            throw APIError.badResponse(statusCode: statusCode, body: body)
        }
    }
}