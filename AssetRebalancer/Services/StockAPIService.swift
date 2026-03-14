import Foundation

// MARK: - Stock API Service
actor StockAPIService {
    static let shared = StockAPIService()

    private var cache: [String: (price: Double, timestamp: Date)] = [:]
    private let cacheDuration: TimeInterval = 3600 // 1 hour

    // MARK: - Fetch Price

    func fetchPrice(symbol: String, market: MarketType) async throws -> Double {
        let cacheKey = "\(market.rawValue):\(symbol)"

        // Check cache
        if let cached = cache[cacheKey],
           Date().timeIntervalSince(cached.timestamp) < cacheDuration {
            return cached.price
        }

        let price: Double
        switch market {
        case .tw:
            price = try await fetchTWStockPrice(symbol: symbol)
        case .us:
            price = try await fetchUSStockPrice(symbol: symbol)
        }

        cache[cacheKey] = (price, Date())
        return price
    }

    // MARK: - TWSE OpenAPI

    private func fetchTWStockPrice(symbol: String) async throws -> Double {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let today = dateFormatter.string(from: Date())

        let urlString = "https://www.twse.com.tw/exchangeReport/STOCK_DAY?response=json&date=\(today)&stockNo=\(symbol)"
        guard let url = URL(string: urlString) else {
            throw StockAPIError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataArray = json["data"] as? [[String]],
              let lastRow = dataArray.last else {
            // Try alternative: fetch from previous month if no data today
            return try await fetchTWSEAlternative(symbol: symbol)
        }

        // Column 6 is closing price (index 6)
        let priceString = lastRow[6].replacingOccurrences(of: ",", with: "")
        guard let price = Double(priceString) else {
            throw StockAPIError.parseError
        }

        return price
    }

    private func fetchTWSEAlternative(symbol: String) async throws -> Double {
        // Try fetching real-time quote
        let urlString = "https://mis.twse.com.tw/stock/api/getStockInfo.jsp?ex_ch=tse_\(symbol).tw"
        guard let url = URL(string: urlString) else {
            throw StockAPIError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let msgArray = json["msgArray"] as? [[String: Any]],
              let first = msgArray.first,
              let priceStr = first["z"] as? String,
              let price = Double(priceStr) else {
            throw StockAPIError.noData
        }

        return price
    }

    // MARK: - Yahoo Finance (US Stocks)

    private func fetchUSStockPrice(symbol: String) async throws -> Double {
        let urlString = "https://query1.finance.yahoo.com/v8/finance/chart/\(symbol)?interval=1d&range=1d"
        guard let url = URL(string: urlString) else {
            throw StockAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: request)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let chart = json["chart"] as? [String: Any],
              let results = chart["result"] as? [[String: Any]],
              let first = results.first,
              let meta = first["meta"] as? [String: Any],
              let price = meta["regularMarketPrice"] as? Double else {
            throw StockAPIError.parseError
        }

        return price
    }

    // MARK: - Clear Cache

    func clearCache() {
        cache.removeAll()
    }
}

// MARK: - Errors
enum StockAPIError: LocalizedError {
    case invalidURL
    case parseError
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .parseError: return "Failed to parse stock data"
        case .noData: return "No stock data available"
        }
    }
}
