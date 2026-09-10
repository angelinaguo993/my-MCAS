import Foundation

/// Keeps every backend URL in one place — change the base URL here
/// (e.g. moving from localhost to a deployed server) instead of hunting
/// through every view.
enum Endpoints {
    // While developing in the iOS Simulator, your Mac's backend is reachable
    // at localhost. On a physical device, replace this with your Mac's LAN
    // IP (e.g. "http://192.168.1.23:8000").
    static let baseURL = "http://127.0.0.1:8000"

    static var dashboard: URL { URL(string: "\(baseURL)/dashboard")! }
    static var episodes: URL { URL(string: "\(baseURL)/episodes")! }
    static func episode(id: Int) -> URL { URL(string: "\(baseURL)/episodes/\(id)")! }

    /// For the calendar view, fetching one month at a time.
    static func episodes(year: Int, month: Int) -> URL {
        URL(string: "\(baseURL)/episodes?year=\(year)&month=\(month)")!
    }
}
