import Foundation
import Combine

// MARK: - Portfolio ViewModel
@MainActor
class PortfolioViewModel: ObservableObject {
    @Published var assets: [Asset] = []
    @Published var targetAllocation = TargetAllocation()
    @Published var deviationThreshold: Double = 5.0
    @Published var summary: PortfolioSummary = .empty
    @Published var rebalanceActions: [RebalanceAction] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var errorMessage: String?

    private let firestore = FirestoreService.shared

    // MARK: - Load Data

    func loadAll() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let fetchedAssets = firestore.fetchAssets()
            async let fetchedTarget = firestore.fetchTargetAllocation()
            async let fetchedThreshold = firestore.fetchDeviationThreshold()

            assets = try await fetchedAssets
            targetAllocation = try await fetchedTarget
            deviationThreshold = try await fetchedThreshold

            await refreshPrices()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Refresh Prices

    func refreshPrices() async {
        isRefreshing = true
        defer { isRefreshing = false }

        let exchangeRate: Double
        do {
            exchangeRate = try await ExchangeRateService.shared.getUSDToTWD()
        } catch {
            errorMessage = "Failed to fetch exchange rate"
            recalculate()
            return
        }

        for i in assets.indices {
            let asset = assets[i]

            if asset.category == .stock, let market = asset.marketType {
                do {
                    let price = try await StockAPIService.shared.fetchPrice(
                        symbol: asset.symbol, market: market
                    )
                    assets[i].marketPrice = price

                    switch market {
                    case .tw:
                        assets[i].marketValueTWD = price * asset.shares
                    case .us:
                        assets[i].marketValueTWD = price * asset.shares * exchangeRate
                    }
                } catch {
                    // Use manual price as fallback
                    if let manual = asset.manualPrice {
                        assets[i].marketPrice = manual
                        switch market {
                        case .tw:
                            assets[i].marketValueTWD = manual * asset.shares
                        case .us:
                            assets[i].marketValueTWD = manual * asset.shares * exchangeRate
                        }
                    }
                }
            } else if asset.category == .bond {
                // Bonds use manual value
                assets[i].marketValueTWD = asset.shares
            } else if asset.category == .cash {
                // Cash: shares = amount in TWD
                assets[i].marketValueTWD = asset.shares
            }
        }

        recalculate()
    }

    // MARK: - Recalculate

    func recalculate() {
        summary = Rebalancer.calculateSummary(
            assets: assets, target: targetAllocation
        )
        rebalanceActions = Rebalancer.calculateActions(
            assets: assets, target: targetAllocation, threshold: deviationThreshold
        )
    }

    // MARK: - CRUD

    func addAsset(_ asset: Asset) async {
        assets.append(asset)
        recalculate()

        do {
            try await firestore.saveAsset(asset)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateAsset(_ asset: Asset) async {
        if let index = assets.firstIndex(where: { $0.id == asset.id }) {
            assets[index] = asset
            recalculate()

            do {
                try await firestore.saveAsset(asset)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func deleteAsset(_ assetID: String) async {
        assets.removeAll { $0.id == assetID }
        recalculate()

        do {
            try await firestore.deleteAsset(assetID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Target Allocation

    func saveTarget() async {
        guard targetAllocation.isValid else {
            errorMessage = "Target allocation must sum to 100%"
            return
        }

        recalculate()

        do {
            try await firestore.saveTargetAllocation(targetAllocation)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveThreshold() async {
        recalculate()
        do {
            try await firestore.saveDeviationThreshold(deviationThreshold)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Chart Data

    var chartSegments: [ChartSegment] {
        AssetCategory.allCases.compactMap { category in
            let value = summary.categoryValues[category] ?? 0
            let percentage = summary.categoryPercentages[category] ?? 0
            guard value > 0 else { return nil }
            return ChartSegment(category: category, value: value, percentage: percentage)
        }
    }
}
