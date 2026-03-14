import Foundation

// MARK: - Exchange Rate Service
actor ExchangeRateService {
    static let shared = ExchangeRateService()

    private var cachedRate: Double?
    private var cacheTimestamp: Date?
    private let cacheDuration: TimeInterval = 86400 // 24 hours

    func getUSDToTWD() async throws -> Double {
        // Check cache
        if let rate = cachedRate,
           let timestamp = cacheTimestamp,
           Date().timeIntervalSince(timestamp) < cacheDuration {
            return rate
        }

        // Try multiple sources
        if let rate = try? await fetchFromExchangeRateAPI() {
            cachedRate = rate
            cacheTimestamp = Date()
            return rate
        }

        // Fallback
        if let rate = try? await fetchFromBackupAPI() {
            cachedRate = rate
            cacheTimestamp = Date()
            return rate
        }

        // Default fallback rate
        return cachedRate ?? 32.0
    }

    private func fetchFromExchangeRateAPI() async throws -> Double {
        let urlString = "https://api.exchangerate-api.com/v4/latest/USD"
        guard let url = URL(string: urlString) else {
            throw ExchangeRateError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rates = json["rates"] as? [String: Double],
              let twd = rates["TWD"] else {
            throw ExchangeRateError.parseError
        }

        return twd
    }

    private func fetchFromBackupAPI() async throws -> Double {
        let urlString = "https://open.er-api.com/v6/latest/USD"
        guard let url = URL(string: urlString) else {
            throw ExchangeRateError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rates = json["rates"] as? [String: Double],
              let twd = rates["TWD"] else {
            throw ExchangeRateError.parseError
        }

        return twd
    }

    func clearCache() {
        cachedRate = nil
        cacheTimestamp = nil
    }
}

enum ExchangeRateError: LocalizedError {
    case invalidURL
    case parseError

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .parseError: return "Failed to parse exchange rate"
        }
    }
}
