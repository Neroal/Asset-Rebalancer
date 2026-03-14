import SwiftUI

struct AssetRowView: View {
    let asset: Asset

    var body: some View {
        HStack(spacing: 12) {
            // Category indicator
            Circle()
                .fill(colorForCategory(asset.category))
                .frame(width: 10, height: 10)

            // Symbol & Name
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(asset.symbol)
                        .font(.headline)

                    if let market = asset.marketType {
                        Text(market.rawValue)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray5))
                            .cornerRadius(4)
                    }
                }

                if asset.name != asset.symbol {
                    Text(asset.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Value info
            VStack(alignment: .trailing, spacing: 2) {
                if let valueTWD = asset.marketValueTWD {
                    Text(Rebalancer.formatCurrency(valueTWD))
                        .font(.subheadline)
                        .fontWeight(.medium)
                } else {
                    Text(Rebalancer.formatCurrency(asset.displayValue))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                if asset.category == .stock {
                    if let price = asset.marketPrice {
                        Text("\(String(format: "%.2f", price)) × \(String(format: "%.0f", asset.shares))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(String(format: "%.0f", asset.shares)) 株")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func colorForCategory(_ category: AssetCategory) -> Color {
        switch category {
        case .stock: return .blue
        case .bond: return .green
        case .cash: return .orange
        }
    }
}
