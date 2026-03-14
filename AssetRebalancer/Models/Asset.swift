import Foundation

// MARK: - Asset Category
enum AssetCategory: String, Codable, CaseIterable, Identifiable {
    case stock = "stock"
    case bond = "bond"
    case cash = "cash"

    var id: String { rawValue }

    var displayName: (zh: String, en: String) {
        switch self {
        case .stock: return ("股票", "Stocks")
        case .bond: return ("債券", "Bonds")
        case .cash: return ("現金", "Cash")
        }
    }

    var color: String {
        switch self {
        case .stock: return "StockColor"   // Blue
        case .bond: return "BondColor"     // Green
        case .cash: return "CashColor"     // Gold
        }
    }
}

// MARK: - Market Type
enum MarketType: String, Codable, CaseIterable {
    case tw = "TW"
    case us = "US"

    var displayName: String {
        switch self {
        case .tw: return "台股"
        case .us: return "美股"
        }
    }
}

// MARK: - Asset Model
struct Asset: Identifiable, Codable {
    var id: String
    var category: AssetCategory
    var symbol: String              // Stock symbol or custom name
    var name: String                // Display name
    var shares: Double              // Number of shares (0 for cash/bond amounts)
    var manualPrice: Double?        // Manual price override
    var marketType: MarketType?     // TW or US (for stocks)
    var marketPrice: Double?        // Fetched market price
    var marketValueTWD: Double?     // Calculated value in TWD
    var createdAt: Date
    var updatedAt: Date

    var displayValue: Double {
        if category == .cash {
            return shares // For cash, shares = amount
        }
        if let price = marketPrice ?? manualPrice {
            return shares * price
        }
        return 0
    }

    init(id: String = UUID().uuidString,
         category: AssetCategory,
         symbol: String,
         name: String = "",
         shares: Double,
         manualPrice: Double? = nil,
         marketType: MarketType? = nil) {
        self.id = id
        self.category = category
        self.symbol = symbol
        self.name = name.isEmpty ? symbol : name
        self.shares = shares
        self.manualPrice = manualPrice
        self.marketType = marketType
        self.marketPrice = nil
        self.marketValueTWD = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Target Allocation
struct TargetAllocation: Codable {
    var stock: Double = 60.0
    var bond: Double = 30.0
    var cash: Double = 10.0

    func percentage(for category: AssetCategory) -> Double {
        switch category {
        case .stock: return stock
        case .bond: return bond
        case .cash: return cash
        }
    }

    mutating func setPercentage(_ value: Double, for category: AssetCategory) {
        switch category {
        case .stock: stock = value
        case .bond: bond = value
        case .cash: cash = value
        }
    }

    var isValid: Bool {
        abs(stock + bond + cash - 100.0) < 0.01
    }
}
