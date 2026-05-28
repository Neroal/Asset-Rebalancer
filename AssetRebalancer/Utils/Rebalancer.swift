import Foundation

// MARK: - Rebalancer
struct Rebalancer {

    static func calculateSummary(assets: [Asset], target: TargetAllocation, threshold: Double = 5.0) -> PortfolioSummary {
        var categoryValues: [AssetCategory: Double] = [:]
        for category in AssetCategory.allCases {
            categoryValues[category] = 0
        }

        for asset in assets {
            let value: Double
            if let twdValue = asset.marketValueTWD {
                value = twdValue
            } else if asset.marketType == .us {
                // US stock without a converted TWD value — displayValue is in USD, don't use it
                value = 0
            } else {
                value = asset.displayValue
            }
            categoryValues[asset.category, default: 0] += value
        }

        let totalValue = categoryValues.values.reduce(0, +)

        var categoryPercentages: [AssetCategory: Double] = [:]
        var deviations: [AssetCategory: Double] = [:]

        for category in AssetCategory.allCases {
            let value = categoryValues[category] ?? 0
            let percentage = totalValue > 0 ? (value / totalValue) * 100 : 0
            categoryPercentages[category] = percentage
            deviations[category] = percentage - target.percentage(for: category)
        }

        let needsRebalance = deviations.values.contains { abs($0) > threshold }

        return PortfolioSummary(
            totalValueTWD: totalValue,
            categoryValues: categoryValues,
            categoryPercentages: categoryPercentages,
            deviations: deviations,
            needsRebalance: needsRebalance
        )
    }

    // Accepts a pre-computed summary to avoid recalculating it inside calculateActions.
    static func calculateActions(
        summary: PortfolioSummary,
        target: TargetAllocation,
        threshold: Double = 5.0
    ) -> [RebalanceAction] {
        let total = summary.totalValueTWD
        guard total > 0 else { return [] }

        var actions: [RebalanceAction] = []

        for category in AssetCategory.allCases {
            let currentPercent = summary.categoryPercentages[category] ?? 0
            let targetPercent = target.percentage(for: category)
            let deviation = currentPercent - targetPercent

            if abs(deviation) < threshold {
                actions.append(RebalanceAction(category: category, action: .hold, amountTWD: 0))
            } else if deviation > 0 {
                actions.append(RebalanceAction(category: category, action: .sell, amountTWD: (deviation / 100.0) * total))
            } else {
                actions.append(RebalanceAction(category: category, action: .buy, amountTWD: abs(deviation / 100.0) * total))
            }
        }

        return actions
    }

    // MARK: - Formatting

    private static let currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        f.groupingSeparator = ","
        return f
    }()

    static func formatCurrency(_ value: Double, symbol: String = "NT$") -> String {
        let formatted = currencyFormatter.string(from: NSNumber(value: value)) ?? "0"
        return "\(symbol)\(formatted)"
    }

    static func formatPercentage(_ value: Double) -> String {
        return String(format: "%.1f%%", value)
    }
}
