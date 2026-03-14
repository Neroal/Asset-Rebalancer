import Foundation

// MARK: - Portfolio Summary
struct PortfolioSummary {
    let totalValueTWD: Double
    let categoryValues: [AssetCategory: Double]
    let categoryPercentages: [AssetCategory: Double]
    let deviations: [AssetCategory: Double]
    let needsRebalance: Bool

    static let empty = PortfolioSummary(
        totalValueTWD: 0,
        categoryValues: [:],
        categoryPercentages: [:],
        deviations: [:],
        needsRebalance: false
    )
}

// MARK: - Rebalance Action
struct RebalanceAction: Identifiable {
    let id = UUID()
    let category: AssetCategory
    let action: ActionType
    let amountTWD: Double

    enum ActionType {
        case buy
        case sell
        case hold

        var displayName: (zh: String, en: String) {
            switch self {
            case .buy: return ("買入", "Buy")
            case .sell: return ("賣出", "Sell")
            case .hold: return ("持有", "Hold")
            }
        }
    }
}

// MARK: - Pie Chart Segment
struct ChartSegment: Identifiable {
    let id = UUID()
    let category: AssetCategory
    let value: Double
    let percentage: Double
}
