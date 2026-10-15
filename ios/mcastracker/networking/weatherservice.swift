import Foundation

class WeatherService {
    static let shared = WeatherService()
    
    // Fetches current temperature, pressure, and humidity for a given city.
    func fetchWeather(for city: String) async -> String? {
        guard let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let geoUrl = URL(string: "https://geocoding-api.open-meteo.com/v1/search?name=\(encodedCity)&count=1") else {
            return nil
        }
        
        do {
            // 1. lat and long
            let (geoData, _) = try await URLSession.shared.data(from: geoUrl)
            let geoResponse = try JSONDecoder().decode(GeoResponse.self, from: geoData)
            guard let location = geoResponse.results?.first else { return nil }
            
            // 2. fetch weather from coordinates from 1
            let weatherUrlString = "https://api.open-meteo.com/v1/forecast?latitude=\(location.latitude)&longitude=\(location.longitude)&current=temperature_2m,relative_humidity_2m,pressure_msl"
            guard let weatherUrl = URL(string: weatherUrlString) else { return nil }
            
            let (weatherData, _) = try await URLSession.shared.data(from: weatherUrl)
            let weatherResponse = try JSONDecoder().decode(WeatherResponse.self, from: weatherData)
            
            // celsius -> farenheit
            let tempF = (weatherResponse.current.temperature_2m * 9/5) + 32
            let humidity = weatherResponse.current.relative_humidity_2m
            let pressure = weatherResponse.current.pressure_msl
            
            return String(format: "%.1f°F, Pressure: %.1f hPa, Humidity: %d%%", tempF, pressure, humidity)
        } catch {
            print("Failed to fetch weather: \(error)")
            return nil
        }
    }

    /// Compares archived daily weather on recorded episode days with days that
    /// have no episode logged, using the user's configured city.
    func comparisonContext(for episodes: [Episode], city: String) async -> String? {
        guard !episodes.isEmpty,
              let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let geoURL = URL(string: "https://geocoding-api.open-meteo.com/v1/search?name=\(encodedCity)&count=1"),
              let end = Calendar.current.date(byAdding: .day, value: -5, to: Date()),
              let start = Calendar.current.date(byAdding: .day, value: -35, to: end) else { return nil }
        do {
            let (geoData, _) = try await URLSession.shared.data(from: geoURL)
            guard let place = try JSONDecoder().decode(GeoResponse.self, from: geoData).results?.first else { return nil }
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.timeZone = TimeZone.current
            formatter.dateFormat = "yyyy-MM-dd"
            let urlString = "https://archive-api.open-meteo.com/v1/archive?latitude=\(place.latitude)&longitude=\(place.longitude)&start_date=\(formatter.string(from: start))&end_date=\(formatter.string(from: end))&daily=temperature_2m_mean,relative_humidity_2m_mean,pressure_msl_mean&temperature_unit=fahrenheit&timezone=auto"
            guard let url = URL(string: urlString) else { return nil }
            let (data, _) = try await URLSession.shared.data(from: url)
            let archive = try JSONDecoder().decode(ArchiveResponse.self, from: data)
            let episodeDays = Set(episodes.flatMap { episode -> [String] in
                let first = Calendar.current.startOfDay(for: episode.date)
                let last = Calendar.current.startOfDay(for: episode.endDate ?? episode.date)
                var result: [String] = []
                var day = first
                while day <= last {
                    result.append(formatter.string(from: day))
                    guard let next = Calendar.current.date(byAdding: .day, value: 1, to: day) else { break }
                    day = next
                }
                return result
            })
            let rows = archive.daily.time.indices.compactMap { index -> (Bool, Double?, Double?, Double?)? in
                guard index < archive.daily.temperature.count,
                      index < archive.daily.humidity.count,
                      index < archive.daily.pressure.count else { return nil }
                let isEpisode = episodeDays.contains(archive.daily.time[index])
                return (isEpisode, archive.daily.temperature[index], archive.daily.humidity[index], archive.daily.pressure[index])
            }
            func averages(_ values: [Double?]) -> String {
                let present = values.compactMap { $0 }
                guard !present.isEmpty else { return "insufficient data" }
                return String(format: "%.1f", present.reduce(0, +) / Double(present.count))
            }
            let episodeRows = rows.filter { $0.0 }
            let otherRows = rows.filter { !$0.0 }
            guard !episodeRows.isEmpty, !otherRows.isEmpty else { return nil }
            return "Archived daily weather for \(city), \(episodeRows.count) episode-days vs \(otherRows.count) days without a logged episode (35-to-5 days ago): mean temperature °F \(averages(episodeRows.map { $0.1 })) vs \(averages(otherRows.map { $0.1 })); humidity % \(averages(episodeRows.map { $0.2 })) vs \(averages(otherRows.map { $0.2 })); pressure hPa \(averages(episodeRows.map { $0.3 })) vs \(averages(otherRows.map { $0.3 })). Days without a log are not confirmed symptom-free."
        } catch {
            print("Failed to fetch weather comparison: \(error)")
            return nil
        }
    }
}

// decoding helpers
private struct GeoResponse: Codable {
    let results: [GeoResult]?
}

private struct GeoResult: Codable {
    let latitude: Double
    let longitude: Double
}

private struct WeatherResponse: Codable {
    let current: CurrentWeather
}

private struct CurrentWeather: Codable {
    let temperature_2m: Double
    let relative_humidity_2m: Int
    let pressure_msl: Double
}

private struct ArchiveResponse: Decodable {
    let daily: Daily
    struct Daily: Decodable {
        let time: [String]
        let temperature: [Double?]
        let humidity: [Double?]
        let pressure: [Double?]
        enum CodingKeys: String, CodingKey {
            case time
            case temperature = "temperature_2m_mean"
            case humidity = "relative_humidity_2m_mean"
            case pressure = "pressure_msl_mean"
        }
    }
}
