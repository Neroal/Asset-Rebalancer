import Foundation

// MARK: - Rebalancer
struct Rebalancer {

    static func calculateSummary(assets: [Asset], target: TargetAllocation) -> PortfolioSummary {
        var categoryValues: [AssetCategory: Double] = [:]
        for category in AssetCategory.allCases {
            categoryValues[category] = 0
        }

        // Sum up values per category
        for asset in assets {
            let value = asset.marketValueTWD ?? asset.displayValue
            categoryValues[asset.category, default: 0] += value
        }

        let totalValue = categoryValues.values.reduce(0, +)

        // Calculate percentages and deviations
        var categoryPercentages: [AssetCategory: Double] = [:]
        var deviations: [AssetCategory: Double] = [:]

        for category in AssetCategory.allCases {
            let value = categoryValues[category] ?? 0
            let percentage = totalValue > 0 ? (value / totalValue) * 100 : 0
            categoryPercentages[category] = percentage
            deviations[category] = percentage - target.percentage(for: category)
        }

        let needsRebalance = deviations.values.contains { abs($0) > 5.0 }

        return PortfolioSummary(
            totalValueTWD: totalValue,
            categoryValues: categoryValues,
            categoryPercentages: categoryPercentages,
            deviations: deviations,
            needsRebalance: needsRebalance
        )
    }

    static func calculateActions(
        assets: [Asset],
        target: TargetAllocation,
        threshold: Double = 5.0
    ) -> [RebalanceAction] {
        let summary = calculateSummary(assets: assets, target: target)
        let total = summary.totalValueTWD

        guard total > 0 else { return [] }

        var actions: [RebalanceAction] = []

        for category in AssetCategory.allCases {
            let currentPercent = summary.categoryPercentages[category] ?? 0
            let targetPercent = target.percentage(for: category)
            let deviation = currentPercent - targetPercent

            if abs(deviation) < threshold {
                actions.append(RebalanceAction(
                    category: category,
                    action: .hold,
                    amountTWD: 0
                ))
            } else if deviation > 0 {
                let amount = (deviation / 100.0) * total
                actions.append(RebalanceAction(
                    category: category,
                    action: .sell,
                    amountTWD: amount
                ))
            } else {
                let amount = abs(deviation / 100.0) * total
                actions.append(RebalanceAction(
                    category: category,
                    action: .buy,
                    amountTWD: amount
                ))
            }
        }

        return actions
    }

    // MARK: - Formatting

    static func formatCurrency(_ value: Double, symbol: String = "NT$") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","
        let formatted = formatter.string(from: NSNumber(value: value)) ?? "0"
        return "\(symbol)\(formatted)"
    }

    static func formatPercentage(_ value: Double) -> String {
        return String(format: "%.1f%%", value)
    }
}
