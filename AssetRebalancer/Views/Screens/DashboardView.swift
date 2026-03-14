import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var portfolioVM: PortfolioViewModel
    @EnvironmentObject var lang: LanguageViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Total Assets Card
                    totalAssetsCard

                    // Pie Chart
                    if !portfolioVM.chartSegments.isEmpty {
                        pieChartSection
                    }

                    // Rebalance Status
                    rebalanceStatusCard

                    // Deviation Cards
                    deviationSection

                    // Rebalance Suggestions
                    if portfolioVM.summary.needsRebalance {
                        rebalanceSuggestionsSection
                    }
                }
                .padding()
            }
            .refreshable {
                await portfolioVM.refreshPrices()
            }
            .navigationTitle(lang.tabDashboard)
            .overlay {
                if portfolioVM.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.ultraThinMaterial)
                }
            }
        }
    }

    // MARK: - Total Assets Card

    private var totalAssetsCard: some View {
        VStack(spacing: 8) {
            Text(lang.totalAssets)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(Rebalancer.formatCurrency(portfolioVM.summary.totalValueTWD))
                .font(.system(size: 36, weight: .bold, design: .rounded))

            if portfolioVM.isRefreshing {
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text(lang.pullToRefresh)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - Pie Chart

    private var pieChartSection: some View {
        VStack(spacing: 16) {
            Text(lang.currentAllocation)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            PieChartView(
                segments: portfolioVM.chartSegments,
                centerText: Rebalancer.formatCurrency(portfolioVM.summary.totalValueTWD)
            )
            .frame(height: 220)

            // Legend
            HStack(spacing: 24) {
                ForEach(AssetCategory.allCases) { category in
                    let percentage = portfolioVM.summary.categoryPercentages[category] ?? 0
                    HStack(spacing: 6) {
                        Circle()
                            .fill(colorForCategory(category))
                            .frame(width: 10, height: 10)
                        Text("\(category.displayName.zh) \(Rebalancer.formatPercentage(percentage))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - Rebalance Status

    private var rebalanceStatusCard: some View {
        HStack {
            Image(systemName: portfolioVM.summary.needsRebalance
                  ? "exclamationmark.triangle.fill"
                  : "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(portfolioVM.summary.needsRebalance ? .orange : .green)

            Text(portfolioVM.summary.needsRebalance
                 ? lang.rebalanceNeeded
                 : lang.balanced)
                .font(.headline)

            Spacer()
        }
        .padding()
        .background(
            (portfolioVM.summary.needsRebalance ? Color.orange : Color.green)
                .opacity(0.1)
        )
        .cornerRadius(12)
    }

    // MARK: - Deviation Section

    private var deviationSection: some View {
        VStack(spacing: 12) {
            Text("\(lang.currentAllocation) vs \(lang.targetAllocation)")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(AssetCategory.allCases) { category in
                DeviationRow(
                    category: category,
                    current: portfolioVM.summary.categoryPercentages[category] ?? 0,
                    target: portfolioVM.targetAllocation.percentage(for: category),
                    deviation: portfolioVM.summary.deviations[category] ?? 0
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - Rebalance Suggestions

    private var rebalanceSuggestionsSection: some View {
        VStack(spacing: 12) {
            Text(lang.rebalanceSuggestions)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(portfolioVM.rebalanceActions) { action in
                if action.action != .hold {
                    HStack {
                        Circle()
                            .fill(colorForCategory(action.category))
                            .frame(width: 10, height: 10)

                        Text(lang.language == .zh
                             ? action.category.displayName.zh
                             : action.category.displayName.en)
                            .font(.subheadline)

                        Spacer()

                        Text(action.action == .buy ? lang.buy : lang.sell)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(action.action == .buy ? .green : .red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                (action.action == .buy ? Color.green : Color.red)
                                    .opacity(0.15)
                            )
                            .cornerRadius(6)

                        Text(Rebalancer.formatCurrency(action.amountTWD))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - Helpers

    private func colorForCategory(_ category: AssetCategory) -> Color {
        switch category {
        case .stock: return .blue
        case .bond: return .green
        case .cash: return .orange
        }
    }
}

// MARK: - Deviation Row
struct DeviationRow: View {
    let category: AssetCategory
    let current: Double
    let target: Double
    let deviation: Double

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Circle()
                    .fill(colorForCategory(category))
                    .frame(width: 10, height: 10)

                Text(category.displayName.zh)
                    .font(.subheadline)

                Spacer()

                Text(Rebalancer.formatPercentage(current))
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("/ \(Rebalancer.formatPercentage(target))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(deviation >= 0 ? "+\(Rebalancer.formatPercentage(deviation))" : Rebalancer.formatPercentage(deviation))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(abs(deviation) > 5 ? .red : .secondary)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)

                    // Current value
                    RoundedRectangle(cornerRadius: 4)
                        .fill(colorForCategory(category))
                        .frame(width: max(0, geo.size.width * current / 100), height: 6)

                    // Target marker
                    Rectangle()
                        .fill(Color.primary.opacity(0.5))
                        .frame(width: 2, height: 12)
                        .offset(x: geo.size.width * target / 100 - 1)
                }
            }
            .frame(height: 12)
        }
    }

    private func colorForCategory(_ category: AssetCategory) -> Color {
        switch category {
        case .stock: return .blue
        case .bond: return .green
        case .cash: return .orange
        }
    }
}
