import Foundation

class WeatherService {
    static let shared = WeatherService()
    
    func fetchWeather(for city: String) async -> String? {
        guard let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let geoUrl = URL(string: "https://geocoding-api.open-meteo.com/v1/search?name=\(encodedCity)&count=1") else {
            return nil
        }
        
        do {
            // 1. Get latitude and longitude from city name
            let (geoData, _) = try await URLSession.shared.data(from: geoUrl)
            let geoResponse = try JSONDecoder().decode(GeoResponse.self, from: geoData)
            guard let location = geoResponse.results?.first else { return nil }
            
            // 2. Fetch current weather for those coordinates
            let weatherUrlString = "https://api.open-meteo.com/v1/forecast?latitude=\(location.latitude)&longitude=\(location.longitude)&current=temperature_2m,relative_humidity_2m"
            guard let weatherUrl = URL(string: weatherUrlString) else { return nil }
            
            let (weatherData, _) = try await URLSession.shared.data(from: weatherUrl)
            let weatherResponse = try JSONDecoder().decode(WeatherResponse.self, from: weatherData)
            
            // Convert Celsius to Fahrenheit (Open-Meteo returns Celsius by default)
            let tempF = (weatherResponse.current.temperature_2m * 9/5) + 32
            let humidity = weatherResponse.current.relative_humidity_2m
            
            return String(format: "%.1f°F, Humidity: %d%%", tempF, humidity)
        } catch {
            print("Failed to fetch weather: \(error)")
            return nil
        }
    }
}

// MARK: - Decoding Helpers
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
}