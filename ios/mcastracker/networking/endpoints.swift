import Foundation

/// Keeps every backend URL in one place — change the base URL here
/// (e.g. moving from localhost to a deployed server) instead of hunting
/// through every view.
enum Endpoints {
    static let baseURL = "https://my-mcas.onrender.com"

    static var dashboard: URL { URL(string: "\(baseURL)/dashboard")! }
    static var episodes: URL { URL(string: "\(baseURL)/episodes")! }
    static var insights: URL { URL(string: "\(baseURL)/insights")! }
    static func episode(id: Int) -> URL { URL(string: "\(baseURL)/episodes/\(id)")! }

    /// For the calendar view, fetching one month at a time.
    static func episodes(year: Int, month: Int) -> URL {
        URL(string: "\(baseURL)/episodes?year=\(year)&month=\(month)")!
    }
}
